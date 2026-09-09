import type { WebSocket } from "@fastify/websocket";

const socketsBySessionId = new Map<string, Set<WebSocket>>();

export function addSessionSocket(sessionId: string, socket: WebSocket) {
    const sockets = socketsBySessionId.get(sessionId) ?? new Set<WebSocket>();
    sockets.add(socket);
    socketsBySessionId.set(sessionId, sockets);

    return () => {
        sockets.delete(socket);
        if (sockets.size === 0) {
            socketsBySessionId.delete(sessionId);
        }
    };
}

export function closeSessionSockets(sessionId: string, reason: string) {
    const sockets = socketsBySessionId.get(sessionId);

    for (const socket of sockets ?? []) {
        socket.close(1008, reason);
    }
}
