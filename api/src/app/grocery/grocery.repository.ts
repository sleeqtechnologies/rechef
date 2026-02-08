import { eq, and, asc, sql } from "drizzle-orm";
import db from "../../database";
import { groceryListTable, groceryListItemTable } from "./grocery.table";
import { recipeTable } from "../recipe/recipe.table";

type GroceryList = typeof groceryListTable.$inferSelect;
type GroceryItem = typeof groceryListItemTable.$inferSelect;
type NewGroceryItem = typeof groceryListItemTable.$inferInsert;

const findOrCreateList = async (userId: string): Promise<GroceryList> => {
  const [existing] = await db
    .select()
    .from(groceryListTable)
    .where(
      and(
        eq(groceryListTable.userId, userId),
        eq(groceryListTable.status, "active"),
      ),
    )
    .limit(1);

  if (existing) return existing;

  const [created] = await db
    .insert(groceryListTable)
    .values({ userId, name: "Grocery List" })
    .returning();

  return created;
};

const addItems = async (items: NewGroceryItem[]): Promise<GroceryItem[]> => {
  if (items.length === 0) return [];
  return db.insert(groceryListItemTable).values(items).returning();
};

const findByListAndRecipe = async (
  groceryListId: string,
  recipeId: string,
): Promise<GroceryItem[]> => {
  return db
    .select()
    .from(groceryListItemTable)
    .where(
      and(
        eq(groceryListItemTable.groceryListId, groceryListId),
        eq(groceryListItemTable.recipeId, recipeId),
      ),
    );
};

interface GroceryItemWithRecipe {
  id: string;
  groceryListId: string;
  recipeId: string | null;
  name: string;
  quantity: string | null;
  unit: string | null;
  category: string;
  checked: boolean;
  createdAt: Date;
  recipeName: string | null;
}

const findItemsByUserId = async (
  userId: string,
): Promise<GroceryItemWithRecipe[]> => {
  const list = await findOrCreateList(userId);

  const rows = await db
    .select({
      id: groceryListItemTable.id,
      groceryListId: groceryListItemTable.groceryListId,
      recipeId: groceryListItemTable.recipeId,
      name: groceryListItemTable.name,
      quantity: groceryListItemTable.quantity,
      unit: groceryListItemTable.unit,
      category: groceryListItemTable.category,
      checked: groceryListItemTable.checked,
      createdAt: groceryListItemTable.createdAt,
      recipeName: recipeTable.name,
    })
    .from(groceryListItemTable)
    .leftJoin(recipeTable, eq(groceryListItemTable.recipeId, recipeTable.id))
    .where(eq(groceryListItemTable.groceryListId, list.id))
    .orderBy(asc(groceryListItemTable.checked), asc(groceryListItemTable.createdAt));

  return rows as unknown as GroceryItemWithRecipe[];
};

const toggleItem = async (
  itemId: string,
): Promise<GroceryItem | undefined> => {
  const [updated] = await db
    .update(groceryListItemTable)
    .set({ checked: sql`NOT ${groceryListItemTable.checked}` })
    .where(eq(groceryListItemTable.id, itemId))
    .returning();

  return updated;
};

const deleteItem = async (itemId: string): Promise<void> => {
  await db
    .delete(groceryListItemTable)
    .where(eq(groceryListItemTable.id, itemId));
};

const clearChecked = async (userId: string): Promise<void> => {
  const list = await findOrCreateList(userId);
  await db
    .delete(groceryListItemTable)
    .where(
      and(
        eq(groceryListItemTable.groceryListId, list.id),
        eq(groceryListItemTable.checked, true),
      ),
    );
};

export {
  findOrCreateList,
  addItems,
  findByListAndRecipe,
  findItemsByUserId,
  toggleItem,
  deleteItem,
  clearChecked,
};
export type { GroceryList, GroceryItem, NewGroceryItem };
