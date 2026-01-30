import { pgTable, varchar } from "drizzle-orm/pg-core";
import { createdAt, dbId, updatedAt } from "../../database/shared-drizzle";

const userTable = pgTable("users", {
  id: dbId,
  firebaseAuthUid: varchar("firebase_auth_uid", { length: 255 }).notNull(),
  name: varchar("name", { length: 255 }).notNull(),
  email: varchar("email", { length: 255 }).notNull(),
  createdAt,
  updatedAt,
});

export { userTable };
