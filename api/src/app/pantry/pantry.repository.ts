import { eq, asc, isNull } from "drizzle-orm";
import db from "../../database";
import { userPantryTable } from "./pantry.table";

type PantryItem = typeof userPantryTable.$inferSelect;
type NewPantryItem = typeof userPantryTable.$inferInsert;

const createMany = async (items: NewPantryItem[]): Promise<PantryItem[]> => {
  if (items.length === 0) return [];
  return db.insert(userPantryTable).values(items).returning();
};

const findAllByUserId = async (userId: string): Promise<PantryItem[]> => {
  return db
    .select()
    .from(userPantryTable)
    .where(eq(userPantryTable.userId, userId))
    .orderBy(asc(userPantryTable.category), asc(userPantryTable.name));
};

const findById = async (id: string): Promise<PantryItem | undefined> => {
  const [item] = await db
    .select()
    .from(userPantryTable)
    .where(eq(userPantryTable.id, id))
    .limit(1);
  return item;
};

const deleteById = async (id: string): Promise<void> => {
  await db.delete(userPantryTable).where(eq(userPantryTable.id, id));
};

const deleteAllByUserId = async (userId: string): Promise<void> => {
  await db.delete(userPantryTable).where(eq(userPantryTable.userId, userId));
};

const updateImageUrl = async (id: string, imageUrl: string): Promise<void> => {
  await db
    .update(userPantryTable)
    .set({ imageUrl })
    .where(eq(userPantryTable.id, id));
};

export {
  createMany,
  findAllByUserId,
  findById,
  deleteById,
  deleteAllByUserId,
  updateImageUrl,
};
export type { PantryItem, NewPantryItem };
