import fs from "node:fs/promises";
import path from "node:path";
import { app } from "../main.js";
import { FastifyPluginAsync } from "fastify";
import { pathToFileURL } from "node:url";

export async function loadApiRoutes() {
    try {
        const routes = await fs.readdir(
            path.join(import.meta.dirname, "../services"),
        );
        for (const route of routes) {
            let routePath = path.join(
                import.meta.dirname,
                "../services",
                route,
            );

            routePath = pathToFileURL(routePath).href;

            try {
                const { default: routeModule } = await import(routePath);
                for (const [version, router] of Object.entries(
                    routeModule.versions,
                ) as [string, FastifyPluginAsync][]) {
                    app.register(router, {
                        prefix: `/api/${version}/${routeModule.name}`,
                    });
                }
            } catch (error) {
                throw new Error(`Failed to load route ${route}: ${error}`);
            }
        }
    } catch (error) {
        throw new Error(`Failed to load routes: ${error}`);
    }
}
