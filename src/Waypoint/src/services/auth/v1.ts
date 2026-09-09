import { FastifyPluginAsync } from "fastify";
import { randomBytes, createHash } from "node:crypto";
import { ulid } from "ulid";
import { and, asc, eq, gt, lte } from "drizzle-orm";
import { db } from "../../external/db.js";
import { sessions } from "../../external/schema.js";
import { closeSessionSockets } from "../ws/session-sockets.js";

export interface Session {
    id: string;
    userId: string;
    hashedToken: string;
    createdAt: Date;
    expiresAt: Date;
}

export const authPlugin: FastifyPluginAsync = async (fastify, opts) => {
    fastify.post("/roblox", async (req, res) => {
        const body = req.body as { userId: string };
        const userId = body.userId;

        if (!userId) {
            return res.status(400).send({ error: "userId is required" });
        }

        const now = new Date();
        await db
            .delete(sessions)
            .where(
                and(eq(sessions.userId, userId), lte(sessions.expiresAt, now)),
            );

        const activeSessions = await db
            .select({ id: sessions.id })
            .from(sessions)
            .where(
                and(eq(sessions.userId, userId), gt(sessions.expiresAt, now)),
            )
            .orderBy(asc(sessions.createdAt));

        for (const session of activeSessions.slice(0, -2)) {
            await db.delete(sessions).where(eq(sessions.id, session.id));
            closeSessionSockets(session.id, "Token revoked");
        }

        const token = randomBytes(32).toString("base64url");
        const hashedToken = createHash("sha256").update(token).digest("hex");

        await db.insert(sessions).values({
            id: ulid(),
            userId,
            hashedToken,
            expiresAt: new Date(new Date().getTime() + 1000 * 60 * 60 * 24),
            createdAt: new Date(),
        });

        res.send({ token });
    });

    fastify.post("/check", async (req, res) => {
        const body = req.body as { userId: string };
        const userId = body.userId;
        const token = req.headers.authorization?.slice(7);

        if (!token || !userId) {
            return res
                .status(400)
                .send({ error: "token and userId are required" });
        }

        const hashedToken = createHash("sha256").update(token).digest("hex");
        const session = await db
            .select()
            .from(sessions)
            .where(
                and(
                    eq(sessions.hashedToken, hashedToken),
                    eq(sessions.userId, userId),
                    gt(sessions.expiresAt, new Date()),
                ),
            );

        if (session.length === 0) {
            await db
                .delete(sessions)
                .where(
                    and(
                        eq(sessions.hashedToken, hashedToken),
                        lte(sessions.expiresAt, new Date()),
                    ),
                );

            return res.status(404).send({ error: "session not found" });
        }

        res.send({ success: true });
    });
};
