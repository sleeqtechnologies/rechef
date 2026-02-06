import {
  integer,
  jsonb,
  pgEnum,
  pgTable,
  text,
  uuid,
  varchar,
} from "drizzle-orm/pg-core";
import { createdAt, dbId, updatedAt } from "../../database/shared-drizzle";
import { userTable } from "../user/user.table";

const contentTypeEnum = pgEnum("content_type", ["video", "image", "website"]);
const contentStatusEnum = pgEnum("content_status", [
  "pending",
  "processed",
  "failed",
]);
const jobStatusEnum = pgEnum("job_status", [
  "pending",
  "processing",
  "completed",
  "failed",
]);

const savedContentTable = pgTable("saved_contents", {
  id: dbId,
  userId: uuid("user_id")
    .notNull()
    .references(() => userTable.id),
  contentType: contentTypeEnum().notNull(),
  sourceUrl: varchar("source_url", { length: 2048 }).notNull(),
  title: varchar("title", { length: 255 }),
  thumbnailUrl: text("thumbnail_url"),
  status: contentStatusEnum().notNull().default("pending"),
  createdAt,
  updatedAt,
});

const contentJobTable = pgTable("content_jobs", {
  id: dbId,
  userId: uuid("user_id")
    .notNull()
    .references(() => userTable.id),
  savedContentId: uuid("saved_content_id").references(
    () => savedContentTable.id
  ),
  status: jobStatusEnum().notNull().default("pending"),
  progress: integer("progress").default(0),
  result: jsonb("result"),
  error: text("error"),
  createdAt,
  updatedAt,
});

export {
  savedContentTable,
  contentJobTable,
  contentTypeEnum,
  contentStatusEnum,
  jobStatusEnum,
};
