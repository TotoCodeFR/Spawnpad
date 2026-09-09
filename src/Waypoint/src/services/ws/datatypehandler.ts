import type { WebSocket } from "@fastify/websocket";
import * as Sentry from "@sentry/node";

const dataTypeHandlers: Record<string, (socket: any, data: any) => void> = {};

export function registerDataTypeHandler(
    type: string,
    handler: (socket: WebSocket, data: any) => void,
) {
    dataTypeHandlers[type] = handler;
}

export function handleDataType(socket: WebSocket, type: string, data: any) {
    const handler = dataTypeHandlers[type];
    if (handler) {
        handler(socket, data);
    } else {
        console.warn(`No handler for data type "${type}"`);
        socket.send(
            JSON.stringify({
                type: "error",
                data: {
                    message: `No handler for data type "${type}"`,
                },
            }),
        );
        Sentry.captureMessage(`No handler for data type "${type}"`, {
            level: "warning",
        });
    }
}
