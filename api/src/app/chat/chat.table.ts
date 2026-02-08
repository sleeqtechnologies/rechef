import { pgTable, text, uuid } from "drizzle-orm/pg-core";
import { createdAt, dbId } from "../../database/shared-drizzle";
import { userTable } from "../user/user.table";
import { recipeTable } from "../recipe/recipe.table";

const chatMessageTable = pgTable("chat_messages", {
  id: dbId,
  userId: uuid("user_id")
    .notNull()
    .references(() => userTable.id),
  recipeId: uuid("recipe_id")
    .notNull()
    .references(() => recipeTable.id, { onDelete: "cascade" }),
  role: text("role").notNull(), // 'user' | 'assistant'
  content: text("content").notNull(),
  imageBase64: text("image_base64"), // nullable, for user-uploaded photos
  createdAt,
});

export { chatMessageTable };
