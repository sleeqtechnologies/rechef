import { eq } from "drizzle-orm";
import db from "../../database";
import { recipeNutritionTable } from "./recipe-nutrition.table";

type RecipeNutrition = typeof recipeNutritionTable.$inferSelect;
type NewRecipeNutrition = typeof recipeNutritionTable.$inferInsert;

const findByRecipeId = async (
  recipeId: string,
): Promise<RecipeNutrition | undefined> => {
  const [row] = await db
    .select()
    .from(recipeNutritionTable)
    .where(eq(recipeNutritionTable.recipeId, recipeId))
    .limit(1);

  return row;
};

const create = async (data: NewRecipeNutrition): Promise<RecipeNutrition> => {
  const [row] = await db
    .insert(recipeNutritionTable)
    .values(data)
    .returning();

  return row;
};

export { findByRecipeId, create };
export type { RecipeNutrition, NewRecipeNutrition };

