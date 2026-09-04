import { FastifyPluginAsync } from "fastify";
import websocket from "@fastify/websocket";
import { handleDataType } from "./datatypehandler.js";
import fs from "fs/promises";
import path from "path";
import { pathToFileURL } from "url";
import { db } from "../../external/db.js";
import { sessions } from "../../external/schema.js";
import { and, eq, gt, lte } from "drizzle-orm";
import { createHash } from "node:crypto";
import type { WebSocket } from "@fastify/websocket";

type WebsocketResponse = {
    type: string;
    data: any;
};

const socketsBySessionId = new Map<string, Set<WebSocket>>();
const expirationTimers = new Map<string, NodeJS.Timeout>();

function closeSessionSockets(sessionId: string) {
    const sockets = socketsBySessionId.get(sessionId);

    for (const socket of sockets ?? []) {
        socket.close(1008, "Token expired");
    }
}

async function deleteExpiredSession(sessionId: string) {
    const timer = expirationTimers.get(sessionId);
    if (timer) {
        clearTimeout(timer);
    }

    try {
        await db
            .delete(sessions)
            .where(
                and(
                    eq(sessions.id, sessionId),
                    lte(sessions.expiresAt, new Date()),
                ),
            );
    } finally {
        closeSessionSockets(sessionId);
        expirationTimers.delete(sessionId);
    }
}

function scheduleSessionExpiration(
    sessionId: string,
    expiresAt: Date,
    onError: (error: unknown) => void,
) {
    if (expirationTimers.has(sessionId)) {
        return;
    }

    const delay = Math.max(0, expiresAt.getTime() - Date.now());
    const timer = setTimeout(() => {
        void deleteExpiredSession(sessionId).catch(onError);
    }, delay);

    expirationTimers.set(sessionId, timer);
}

async function deleteAllExpiredSessions() {
    const expiredSessions = await db
        .select({ id: sessions.id })
        .from(sessions)
        .where(lte(sessions.expiresAt, new Date()));

    for (const { id } of expiredSessions) {
        await deleteExpiredSession(id);
    }
}

async function loadDatatypes() {
    try {
        const datatypes = await fs.readdir(
            path.join(import.meta.dirname, "./datatypes"),
        );
        datatypes.forEach(async (route) => {
            let datatypePath = path.join(
                import.meta.dirname,
                "./datatypes",
                route,
            );

            datatypePath = pathToFileURL(datatypePath).href;

            try {
                await import(datatypePath);
            } catch (error) {
                throw new Error(`Failed to load datatype ${route}: ${error}`);
            }
        });
    } catch (error) {
        throw new Error(`Failed to load datatypes: ${error}`);
    }
}

await loadDatatypes();

export const wsV1: FastifyPluginAsync = async (fastify, opts) => {
    await fastify.register(websocket);

    await deleteAllExpiredSessions();
    const cleanupInterval = setInterval(() => {
        void deleteAllExpiredSessions().catch((error) => {
            fastify.log.error(error, "Failed to delete expired sessions");
        });
    }, 60_000);

    fastify.addHook("onClose", async () => {
        clearInterval(cleanupInterval);

        for (const timer of expirationTimers.values()) {
            clearTimeout(timer);
        }
        expirationTimers.clear();
    });

    fastify.get("/ws", { websocket: true }, async (socket, req) => {
        const token = req.headers.authorization?.slice(7);

        if (!token) {
            socket.close(1008, "Unauthorized");
            return;
        }

        const hashedToken = createHash("sha256").update(token).digest("hex");

        const session = await db.query.sessions.findFirst({
            where: and(
                eq(sessions.hashedToken, hashedToken),
                gt(sessions.expiresAt, new Date()),
            ),
        });

        if (!session) {
            await db
                .delete(sessions)
                .where(
                    and(
                        eq(sessions.hashedToken, hashedToken),
                        lte(sessions.expiresAt, new Date()),
                    ),
                );

            socket.close(1008, "Unauthorized");
            return;
        }

        const { userId, id } = session;

        socket.state = { userId, id };
        const sockets = socketsBySessionId.get(id) ?? new Set<WebSocket>();
        sockets.add(socket);
        socketsBySessionId.set(id, sockets);
        scheduleSessionExpiration(id, session.expiresAt, (error) => {
            fastify.log.error(error, "Failed to expire session");
        });

        socket.on("message", (message: Buffer) => {
            try {
                const { data, type }: WebsocketResponse = JSON.parse(
                    message.toString(),
                );

                handleDataType(socket, type, data);
            } catch (e) {
                throw e;
            }
        });

        socket.on("close", () => {
            sockets.delete(socket);
            if (sockets.size === 0) {
                socketsBySessionId.delete(id);
            }
            console.log("socket closed");
        });
    });
};
