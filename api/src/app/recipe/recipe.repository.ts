import { eq, desc, sql } from "drizzle-orm";
import db from "../../database";
import { recipeTable } from "./recipe.table";
import { sharedRecipeSaveTable, sharedRecipeTable } from "../share/share.table";

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

interface UserRecipeRow {
  recipe: Recipe;
  isShared: boolean;
  shareCode: string | null;
  sharedBy: string | null;
  sharedSaveId: string | null;
}

const findAllForUser = async (userId: string): Promise<UserRecipeRow[]> => {
  const owned = db
    .select({
      recipe: recipeTable,
      isShared: sql<boolean>`false`.as("is_shared"),
      shareCode: sql<string | null>`null`.as("share_code_val"),
      sharedBy: sql<string | null>`null`.as("shared_by_val"),
      sharedSaveId: sql<string | null>`null`.as("shared_save_id_val"),
    })
    .from(recipeTable)
    .where(eq(recipeTable.userId, userId));

  const shared = db
    .select({
      recipe: recipeTable,
      isShared: sql<boolean>`true`.as("is_shared"),
      shareCode: sharedRecipeTable.shareCode,
      sharedBy: sharedRecipeTable.userId,
      sharedSaveId: sharedRecipeSaveTable.id,
    })
    .from(sharedRecipeSaveTable)
    .innerJoin(
      sharedRecipeTable,
      eq(sharedRecipeSaveTable.sharedRecipeId, sharedRecipeTable.id),
    )
    .innerJoin(
      recipeTable,
      eq(sharedRecipeTable.recipeId, recipeTable.id),
    )
    .where(eq(sharedRecipeSaveTable.userId, userId));

  const rows = await owned
    .unionAll(shared)
    .orderBy(desc(recipeTable.createdAt));

  return rows as UserRecipeRow[];
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

interface UpdateRecipeData {
  name?: string;
  description?: string;
  ingredients?: unknown;
  instructions?: string;
  servings?: number | null;
  prepTimeMinutes?: number | null;
  cookTimeMinutes?: number | null;
}

const update = async (id: string, data: UpdateRecipeData): Promise<Recipe> => {
  const [recipe] = await db
    .update(recipeTable)
    .set(data)
    .where(eq(recipeTable.id, id))
    .returning();

  return recipe;
};

const deleteById = async (id: string): Promise<void> => {
  await db.delete(recipeTable).where(eq(recipeTable.id, id));
};

export { create, findAllByUserId, findAllForUser, findById, update, updateIngredients, deleteById };
export type { Recipe, NewRecipe, UpdateRecipeData, UserRecipeRow };
