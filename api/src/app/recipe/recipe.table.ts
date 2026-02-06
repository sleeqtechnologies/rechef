import { integer, jsonb, pgTable, text, uuid, varchar } from "drizzle-orm/pg-core";
import { createdAt, dbId, updatedAt } from "../../database/shared-drizzle";
import { savedContentTable } from "../content/content.table";
import { userTable } from "../user/user.table";

const recipeTable = pgTable("recipes", {
  id: dbId,
  userId: uuid("user_id")
    .notNull()
    .references(() => userTable.id),
  savedContentId: uuid("saved_content_id").references(
    () => savedContentTable.id
  ),
  name: varchar("name", { length: 255 }).notNull(),
  description: text("description").notNull(),
  ingredients: jsonb("ingredients").notNull(),
  instructions: text("instructions").notNull(),
  servings: integer("servings"),
  prepTimeMinutes: integer("prep_time_minutes"),
  cookTimeMinutes: integer("cook_time_minutes"),
  imageUrl: text("image_url"),
  createdAt,
  updatedAt,
});

export { recipeTable };
