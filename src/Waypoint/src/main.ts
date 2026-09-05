import dotenv from "dotenv";
import path from "node:path";
dotenv.config({
    quiet: true,
    path: path.join(import.meta.dirname, "../../../.env"),
});
await import("./external/sentry.js");
import fastify from "fastify";
import * as Sentry from "@sentry/node";
import { loadApiRoutes } from "./api/loader.js";

export const app = fastify();

Sentry.setupFastifyErrorHandler(app);

await loadApiRoutes();

app.get("/", async (req, res) => {
    res.send(
        `Hey user!
You might be wondering what this is. This is Waypoint, Spawnpad's external server. It has yet to have a user-facing interface, so it's nearly blank here.
This is just the API, so you can't see much yet. If you're a developer, you can poke around by looking through the Spawnpad source code.`.trim(),
    );
});

app.listen({ port: Number(process.env.PORT) || 3000 }, () => {
    console.log(`Listening on port ${process.env.PORT || 3000}`);
});
