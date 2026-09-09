import { registerDataTypeHandler } from "../datatypehandler.js";

registerDataTypeHandler("whoami", (socket, data) => {
    if (!socket.state) {
        socket.send(
            JSON.stringify({
                type: "error",
                message: "Not authenticated",
            }),
        );
        return;
    }

    socket.send(
        JSON.stringify({
            type: "whoami",
            data: {
                userId: socket.state.userId,
                id: socket.state.id,
            },
        }),
    );
});
