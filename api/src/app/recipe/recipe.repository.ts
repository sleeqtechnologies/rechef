import { eq, desc } from "drizzle-orm";
import db from "../../database";
import { recipeTable } from "./recipe.table";

type Recipe = typeof recipeTable.$inferSelect;
type NewRecipe = typeof recipeTable.$inferInsert;

const SOURCE_TITLE_MAX = 512;
const SOURCE_AUTHOR_NAME_MAX = 255;

function truncateForDb(data: NewRecipe): NewRecipe {
  const out = { ...data };
  if (typeof out.sourceTitle === "string" && out.sourceTitle.length > SOURCE_TITLE_MAX) {
    out.sourceTitle = out.sourceTitle.slice(0, SOURCE_TITLE_MAX);
  }
  if (typeof out.sourceAuthorName === "string" && out.sourceAuthorName.length > SOURCE_AUTHOR_NAME_MAX) {
    out.sourceAuthorName = out.sourceAuthorName.slice(0, SOURCE_AUTHOR_NAME_MAX);
  }
  return out;
}

const create = async (data: NewRecipe): Promise<Recipe> => {
  const [recipe] = await db
    .insert(recipeTable)
    .values(truncateForDb(data))
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

const updateIngredients = async (
  id: string,
  ingredients: unknown,
): Promise<void> => {
  await db
    .update(recipeTable)
    .set({ ingredients })
    .where(eq(recipeTable.id, id));
};

const deleteById = async (id: string): Promise<void> => {
  await db.delete(recipeTable).where(eq(recipeTable.id, id));
};

export { create, findAllByUserId, findById, updateIngredients, deleteById };
export type { Recipe, NewRecipe };
