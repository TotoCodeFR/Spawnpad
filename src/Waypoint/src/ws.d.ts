import type { WebSocket } from "@fastify/websocket";

declare module "@fastify/websocket" {
    interface WebSocket {
        state: {
            userId: number;
            id: string;
        };
    }
}
