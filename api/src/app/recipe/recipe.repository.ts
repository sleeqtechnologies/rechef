import { eq, desc } from "drizzle-orm";
import db from "../../database";
import { recipeTable } from "./recipe.table";

type Recipe = typeof recipeTable.$inferSelect;
type NewRecipe = typeof recipeTable.$inferInsert;

const create = async (data: NewRecipe): Promise<Recipe> => {
  const [recipe] = await db
    .insert(recipeTable)
    .values(data)
    .returning();

  return recipe;
};

const findAllByUserId = async (userId: string): Promise<Recipe[]> => {
  return db
    .select()
    .from(recipeTable)
    .where(eq(recipeTable.userId, userId))
    .orderBy(desc(recipeTable.createdAt));
};

const findById = async (id: string): Promise<Recipe | undefined> => {
  const [recipe] = await db
    .select()
    .from(recipeTable)
    .where(eq(recipeTable.id, id))
    .limit(1);

  return recipe;
};

const deleteById = async (id: string): Promise<void> => {
  await db.delete(recipeTable).where(eq(recipeTable.id, id));
};

export { create, findAllByUserId, findById, deleteById };
export type { Recipe, NewRecipe };
