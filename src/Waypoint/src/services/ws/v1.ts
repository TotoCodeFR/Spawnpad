import { FastifyPluginAsync } from "fastify";
import websocket from "@fastify/websocket";
import { handleDataType } from "./datatypehandler.js";
import fs from "fs/promises";
import path from "path";
import { pathToFileURL } from "url";
import { db } from "../../external/db.js";
import { sessions } from "../../external/schema.js";
import { eq } from "drizzle-orm";
import { createHash } from "node:crypto";

type WebsocketResponse = {
    type: string;
    data: any;
};

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

    fastify.get("/ws", { websocket: true }, async (socket, req) => {
        const token = req.headers.authorization?.slice(7);

        if (!token) {
            socket.close(1008, "Unauthorized");
            return;
        }

        const hashedToken = createHash("sha256").update(token).digest("hex");

        const session = await db.query.sessions.findFirst({
            where: eq(sessions.hashedToken, hashedToken),
        });

        if (!session) {
            socket.close(1008, "Unauthorized");
            return;
        }

        const { userId, id } = session;

        socket.state = { userId, id };

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
            console.log("socket closed");
        });
    });
};
