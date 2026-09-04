import dotenv from "dotenv";
import { drizzle } from "drizzle-orm/node-postgres";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Pool } from "pg";
import * as schema from "./schema.js";

const currentDirectory = dirname(fileURLToPath(import.meta.url));

dotenv.config({
    path: resolve(currentDirectory, "../../../../.env"),
    quiet: true,
});

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
    throw new Error("DATABASE_URL is not set");
}

const pool = new Pool({ connectionString });

export const db = drizzle({ client: pool, schema });
