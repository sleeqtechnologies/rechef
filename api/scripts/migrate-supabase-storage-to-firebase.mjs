import { randomUUID } from "crypto";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";
import admin from "firebase-admin";
import pg from "pg";
import { createClient } from "@supabase/supabase-js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, "../.env") });

const SUPABASE_BUCKET = "recipe_images";
const FIREBASE_PREFIX = "recipe_images";
const DRY_RUN = process.argv.includes("--dry-run");

const urlColumns = [
  { table: "recipes", column: "image_url" },
  { table: "saved_contents", column: "thumbnail_url" },
  { table: "cookbooks", column: "cover_image_url" },
  { table: "user_pantry", column: "image_url" },
];

function requiredEnv(name) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} is required`);
  return value;
}

function getServiceAccount() {
  const raw = requiredEnv("SERVICE_ACCT_KEY");
  if (raw.startsWith(".") || raw.startsWith("/")) {
    return JSON.parse(fs.readFileSync(path.resolve(process.cwd(), raw), "utf-8"));
  }
  return JSON.parse(raw);
}

function getFirebaseDownloadUrl(bucketName, objectPath, token) {
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodeURIComponent(objectPath)}?alt=media&token=${token}`;
}

function parseSupabaseStoragePath(value) {
  if (!value) return null;

  try {
    const url = new URL(value);
    const marker = `/storage/v1/object/public/${SUPABASE_BUCKET}/`;
    const index = url.pathname.indexOf(marker);
    if (index === -1) return null;
    return decodeURIComponent(url.pathname.slice(index + marker.length));
  } catch {
    return null;
  }
}

async function listSupabaseObjects(storage, prefix = "") {
  const all = [];
  const limit = 1000;

  for (let offset = 0; ; offset += limit) {
    const { data, error } = await storage.from(SUPABASE_BUCKET).list(prefix, {
      limit,
      offset,
      sortBy: { column: "name", order: "asc" },
    });

    if (error) throw new Error(`Failed to list ${prefix || "/"}: ${error.message}`);
    if (!data || data.length === 0) break;

    for (const item of data) {
      const itemPath = prefix ? `${prefix}/${item.name}` : item.name;
      if (item.metadata === null) {
        all.push(...(await listSupabaseObjects(storage, itemPath)));
      } else {
        all.push(itemPath);
      }
    }

    if (data.length < limit) break;
  }

  return all;
}

async function copyObject(storage, bucket, objectPath) {
  const { data, error } = await storage.from(SUPABASE_BUCKET).download(objectPath);
  if (error) throw new Error(`Failed to download ${objectPath}: ${error.message}`);

  const buffer = Buffer.from(await data.arrayBuffer());
  const contentType = data.type || "application/octet-stream";
  const firebasePath = `${FIREBASE_PREFIX}/${objectPath}`;
  const token = randomUUID();

  if (!DRY_RUN) {
    await bucket.file(firebasePath).save(buffer, {
      resumable: false,
      metadata: {
        contentType,
        cacheControl: "public, max-age=31536000",
        metadata: {
          firebaseStorageDownloadTokens: token,
        },
      },
    });
  }

  return getFirebaseDownloadUrl(bucket.name, firebasePath, token);
}

async function updateUrlColumns(client, urlMap) {
  let matched = 0;
  let updated = 0;
  let missingObjects = 0;

  for (const { table, column } of urlColumns) {
    const rows = await client.query(
      `select id, ${column} as url from ${table} where ${column} like $1`,
      [`%/storage/v1/object/public/${SUPABASE_BUCKET}/%`],
    );

    for (const row of rows.rows) {
      matched += 1;
      const objectPath = parseSupabaseStoragePath(row.url);
      const firebaseUrl = objectPath ? urlMap.get(objectPath) : null;

      if (!firebaseUrl) {
        missingObjects += 1;
        console.warn(`No migrated object found for ${table}.${column} id=${row.id}`);
        continue;
      }

      if (!DRY_RUN) {
        await client.query(`update ${table} set ${column} = $1 where id = $2`, [
          firebaseUrl,
          row.id,
        ]);
      }
      updated += 1;
    }
  }

  return { matched, updated, missingObjects };
}

async function main() {
  const supabase = createClient(
    requiredEnv("SUPABASE_URL"),
    requiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false } },
  );

  const serviceAccount = getServiceAccount();
  const projectId = serviceAccount.project_id || serviceAccount.projectId;
  const storageBucket =
    process.env.FIREBASE_STORAGE_BUCKET?.trim() || `${projectId}.firebasestorage.app`;

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    storageBucket,
  });

  const bucket = admin.storage().bucket();
  const [bucketExists] = await bucket.exists();
  if (!bucketExists) throw new Error(`Firebase Storage bucket not found: ${bucket.name}`);

  const client = new pg.Client({ connectionString: requiredEnv("DATABASE_URL") });
  await client.connect();

  try {
    const objectPaths = await listSupabaseObjects(supabase.storage);
    console.log(`Found ${objectPaths.length} Supabase Storage object(s)`);

    const urlMap = new Map();
    for (const objectPath of objectPaths) {
      const firebaseUrl = await copyObject(supabase.storage, bucket, objectPath);
      urlMap.set(objectPath, firebaseUrl);
      console.log(`${DRY_RUN ? "Would copy" : "Copied"} ${objectPath}`);
    }

    const result = await updateUrlColumns(client, urlMap);
    console.log(
      `${DRY_RUN ? "Would update" : "Updated"} ${result.updated}/${result.matched} database URL(s)`,
    );

    if (result.missingObjects > 0) {
      process.exitCode = 1;
    }
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
