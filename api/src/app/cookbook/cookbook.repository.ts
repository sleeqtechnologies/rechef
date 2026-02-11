import { and, count, desc, eq, inArray, sql } from "drizzle-orm";
import db from "../../database";
import { cookbookTable, cookbookRecipeTable } from "./cookbook.table";
import { recipeTable } from "../recipe/recipe.table";

type Cookbook = typeof cookbookTable.$inferSelect;
type NewCookbook = typeof cookbookTable.$inferInsert;
type CookbookRecipe = typeof cookbookRecipeTable.$inferSelect;
type Recipe = typeof recipeTable.$inferSelect;

const create = async (data: NewCookbook): Promise<Cookbook> => {
  const [cookbook] = await db
    .insert(cookbookTable)
    .values(data)
    .returning();
  return cookbook;
};

const findAllByUserId = async (userId: string): Promise<Cookbook[]> => {
  return db
    .select()
    .from(cookbookTable)
    .where(eq(cookbookTable.userId, userId))
    .orderBy(desc(cookbookTable.createdAt));
};

const findById = async (id: string): Promise<Cookbook | undefined> => {
  const [cookbook] = await db
    .select()
    .from(cookbookTable)
    .where(eq(cookbookTable.id, id))
    .limit(1);
  return cookbook;
};

const update = async (
  id: string,
  data: { name?: string; description?: string | null },
): Promise<Cookbook> => {
  const [cookbook] = await db
    .update(cookbookTable)
    .set(data)
    .where(eq(cookbookTable.id, id))
    .returning();
  return cookbook;
};

const deleteById = async (id: string): Promise<void> => {
  await db.delete(cookbookTable).where(eq(cookbookTable.id, id));
};

const getRecipeCountsByCookbookIds = async (
  cookbookIds: string[],
): Promise<Map<string, number>> => {
  if (cookbookIds.length === 0) return new Map();

  const rows = await db
    .select({
      cookbookId: cookbookRecipeTable.cookbookId,
      count: count(),
    })
    .from(cookbookRecipeTable)
    .where(inArray(cookbookRecipeTable.cookbookId, cookbookIds))
    .groupBy(cookbookRecipeTable.cookbookId);

  const map = new Map<string, number>();
  for (const row of rows) {
    map.set(row.cookbookId as string, row.count as number);
  }
  return map;
};

const getCoverImagesByCookbookIds = async (
  cookbookIds: string[],
): Promise<Map<string, string[]>> => {
  if (cookbookIds.length === 0) return new Map();

  // For each cookbook, get up to 3 recipe image_urls (by position)
  const rows = await db
    .select({
      cookbookId: cookbookRecipeTable.cookbookId,
      imageUrl: recipeTable.imageUrl,
    })
    .from(cookbookRecipeTable)
    .innerJoin(recipeTable, eq(cookbookRecipeTable.recipeId, recipeTable.id))
    .where(inArray(cookbookRecipeTable.cookbookId, cookbookIds))
    .orderBy(cookbookRecipeTable.position);

  const map = new Map<string, string[]>();
  for (const row of rows) {
    const cbId = row.cookbookId as string;
    const imgUrl = row.imageUrl as string | null;
    if (!imgUrl) continue;
    const arr = map.get(cbId) ?? [];
    if (arr.length < 3) {
      arr.push(imgUrl);
      map.set(cbId, arr);
    }
  }
  return map;
};

const findRecipesByCookbookId = async (cookbookId: string): Promise<Recipe[]> => {
  const rows = await db
    .select({ recipe: recipeTable })
    .from(cookbookRecipeTable)
    .innerJoin(recipeTable, eq(cookbookRecipeTable.recipeId, recipeTable.id))
    .where(eq(cookbookRecipeTable.cookbookId, cookbookId))
    .orderBy(cookbookRecipeTable.position);

  return (rows as { recipe: Recipe }[]).map((r) => r.recipe);
};

const addRecipesToCookbook = async (
  cookbookId: string,
  recipeIds: string[],
): Promise<void> => {
  if (recipeIds.length === 0) return;

  // Get current max position
  const [maxRow] = await db
    .select({ maxPos: sql<number>`COALESCE(MAX(${cookbookRecipeTable.position}), -1)` })
    .from(cookbookRecipeTable)
    .where(eq(cookbookRecipeTable.cookbookId, cookbookId));

  const maxPos = maxRow?.maxPos as number | undefined;
  let nextPos = (maxPos ?? -1) + 1;

  const values = recipeIds.map((recipeId) => ({
    cookbookId,
    recipeId,
    position: nextPos++,
  }));

  await db
    .insert(cookbookRecipeTable)
    .values(values)
    .onConflictDoNothing();
};

const removeRecipeFromCookbook = async (
  cookbookId: string,
  recipeId: string,
): Promise<void> => {
  await db
    .delete(cookbookRecipeTable)
    .where(
      and(
        eq(cookbookRecipeTable.cookbookId, cookbookId),
        eq(cookbookRecipeTable.recipeId, recipeId),
      ),
    );
};

const findCookbooksByRecipeId = async (
  recipeId: string,
  userId: string,
): Promise<Cookbook[]> => {
  const rows = await db
    .select({ cookbook: cookbookTable })
    .from(cookbookRecipeTable)
    .innerJoin(cookbookTable, eq(cookbookRecipeTable.cookbookId, cookbookTable.id))
    .where(
      and(
        eq(cookbookRecipeTable.recipeId, recipeId),
        eq(cookbookTable.userId, userId),
      ),
    );

  return (rows as { cookbook: Cookbook }[]).map((r) => r.cookbook);
};

export {
  create,
  findAllByUserId,
  findById,
  update,
  deleteById,
  getRecipeCountsByCookbookIds,
  getCoverImagesByCookbookIds,
  findRecipesByCookbookId,
  addRecipesToCookbook,
  removeRecipeFromCookbook,
  findCookbooksByRecipeId,
};
export type { Cookbook, NewCookbook, CookbookRecipe };
