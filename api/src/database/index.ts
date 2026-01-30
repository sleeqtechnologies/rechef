import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";

import { env } from "../../env_config";
import database from "./db";
import schema from "./schema";

const client = postgres(env.DATABASE_URL);

const drizzleClient = drizzle({ client, schema });

const db = database(drizzleClient);

export { client };
export default db;
