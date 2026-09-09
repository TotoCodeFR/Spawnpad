import { config } from "dotenv";
import { defineConfig } from "drizzle-kit";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const currentDirectory = dirname(fileURLToPath(import.meta.url));

config({
    quiet: true,
    path: resolve(currentDirectory, "../../../../.env"),
});

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
    throw new Error("DATABASE_URL is required to run Drizzle commands");
}

export default defineConfig({
    dialect: "postgresql",
    schema: "./src/external/schema.ts",
    out: "./src/external/drizzle",
    dbCredentials: {
        url: connectionString,
    },
});
