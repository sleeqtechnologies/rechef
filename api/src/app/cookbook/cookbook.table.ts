import { integer, pgTable, text, unique, uuid, varchar } from "drizzle-orm/pg-core";
import { createdAt, dbId, updatedAt } from "../../database/shared-drizzle";
import { userTable } from "../user/user.table";
import { recipeTable } from "../recipe/recipe.table";

const cookbookTable = pgTable("cookbooks", {
  id: dbId,
  userId: uuid("user_id")
    .notNull()
    .references(() => userTable.id, { onDelete: "cascade" }),
  name: varchar("name", { length: 255 }).notNull(),
  description: text("description"),
  coverImageUrl: text("cover_image_url"),
  createdAt,
  updatedAt,
});

const cookbookRecipeTable = pgTable(
  "cookbook_recipes",
  {
    id: dbId,
    cookbookId: uuid("cookbook_id")
      .notNull()
      .references(() => cookbookTable.id, { onDelete: "cascade" }),
    recipeId: uuid("recipe_id")
      .notNull()
      .references(() => recipeTable.id, { onDelete: "cascade" }),
    position: integer("position").notNull().default(0),
    createdAt,
  },
  (t) => [unique().on(t.cookbookId, t.recipeId)]
);

export { cookbookTable, cookbookRecipeTable };
