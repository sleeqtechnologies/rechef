import {
  boolean,
  jsonb,
  pgEnum,
  pgTable,
  text,
  uuid,
  varchar,
} from "drizzle-orm/pg-core";
import { createdAt, dbId, updatedAt } from "../../database/shared-drizzle";
import { recipeTable } from "../recipe/recipe.table";
import { userTable } from "../user/user.table";

const shareEventTypeEnum = pgEnum("share_event_type", [
  "web_view",
  "app_open",
  "app_install",
  "recipe_save",
  "grocery_add",
  "grocery_purchase",
]);

const sharedRecipeTable = pgTable("shared_recipes", {
  id: dbId,
  recipeId: uuid("recipe_id")
    .notNull()
    .references(() => recipeTable.id, { onDelete: "cascade" }),
  userId: uuid("user_id")
    .notNull()
    .references(() => userTable.id, { onDelete: "cascade" }),
  shareCode: varchar("share_code", { length: 12 }).notNull(),
  isActive: boolean("is_active").notNull().default(true),
  createdAt,
  updatedAt,
});

const sharedRecipeSaveTable = pgTable("shared_recipe_saves", {
  id: dbId,
  sharedRecipeId: uuid("shared_recipe_id")
    .notNull()
    .references(() => sharedRecipeTable.id, { onDelete: "cascade" }),
  userId: uuid("user_id")
    .notNull()
    .references(() => userTable.id, { onDelete: "cascade" }),
  createdAt,
});

const shareEventTable = pgTable("share_events", {
  id: dbId,
  sharedRecipeId: uuid("shared_recipe_id")
    .notNull()
    .references(() => sharedRecipeTable.id, { onDelete: "cascade" }),
  eventType: shareEventTypeEnum("event_type").notNull(),
  userId: uuid("user_id").references(() => userTable.id, {
    onDelete: "cascade",
  }),
  metadata: jsonb("metadata"),
  ipHash: varchar("ip_hash", { length: 255 }),
  createdAt,
});

export {
  shareEventTable,
  shareEventTypeEnum,
  sharedRecipeSaveTable,
  sharedRecipeTable,
};

