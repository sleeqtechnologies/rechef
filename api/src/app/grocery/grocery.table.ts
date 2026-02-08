import { boolean, pgEnum, pgTable, uuid, varchar } from "drizzle-orm/pg-core";
import { createdAt, dbId, updatedAt } from "../../database/shared-drizzle";
import { userTable } from "../user/user.table";
import { recipeTable } from "../recipe/recipe.table";

const groceryListStatusEnum = pgEnum("grocery_list_status", [
  "active",
  "completed",
  "archived",
]);

const groceryListTable = pgTable("grocery_lists", {
  id: dbId,
  userId: uuid("user_id")
    .notNull()
    .references(() => userTable.id),
  name: varchar("name", { length: 255 }).notNull(),
  status: groceryListStatusEnum().notNull().default("active"),
  createdAt,
  updatedAt,
});

const groceryListItemTable = pgTable("grocery_list_items", {
  id: dbId,
  groceryListId: uuid("grocery_list_id")
    .notNull()
    .references(() => groceryListTable.id),
  recipeId: uuid("recipe_id").references(() => recipeTable.id),
  name: varchar("name", { length: 255 }).notNull(),
  quantity: varchar("quantity", { length: 50 }),
  unit: varchar("unit", { length: 50 }),
  category: varchar("category", { length: 100 }).notNull().default("Other"),
  checked: boolean("checked").notNull().default(false),
  createdAt,
});

export { groceryListTable, groceryListItemTable, groceryListStatusEnum };
