import { FastifyPluginAsync } from "fastify";
import packageJson from "../../../package.json" with { type: "json" };

export const metaV1: FastifyPluginAsync = async (fastify, opts) => {
    fastify.get("/", async (request, reply) => {
        reply.send({
            version: packageJson.version,
            apiVersion: 1,
            sdkVersions: {
                min: "0.0.0",
                max: "0.0.0",
            },
        });
    });
};
