#!/usr/bin/env node
/**
 * Run only the share tables migration (0006).
 * Usage: node scripts/run-share-migration.mjs
 * Requires DATABASE_URL in .env
 */
import postgres from "postgres";
import { readFileSync } from "fs";
import { fileURLToPath } from "url";
import { dirname, join } from "path";
import dotenv from "dotenv";

const __dirname = dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: join(__dirname, "..", ".env") });

const url = process.env.DATABASE_URL;
if (!url) {
  console.error("DATABASE_URL is required");
  process.exit(1);
}

const sql = postgres(url, { prepare: false });

const migrationPath = join(
  __dirname,
  "..",
  "migrations",
  "0006_add-share-tables.sql",
);
const content = readFileSync(migrationPath, "utf-8");

// Split by statement-breakpoint and filter empty / comment-only
const statements = content
  .split(/--> statement-breakpoint\n?/i)
  .map((s) => s.trim())
  .filter((s) => s.length > 0 && !s.startsWith("--"));

async function run() {
  console.log("Running share tables migration...");
  for (let i = 0; i < statements.length; i++) {
    const stmt = statements[i];
    if (!stmt) continue;
    try {
      await sql.unsafe(stmt);
      console.log(`  OK statement ${i + 1}/${statements.length}`);
    } catch (err) {
      if (err.code === "42710" && err.message?.includes("already exists")) {
        console.log(`  SKIP statement ${i + 1} (already exists)`);
      } else {
        console.error(`  FAIL statement ${i + 1}:`, err.message);
        throw err;
      }
    }
  }
  console.log("Done.");
  await sql.end();
}

run().catch((err) => {
  console.error(err);
  process.exit(1);
});
