import { and, count, eq } from "drizzle-orm";
import crypto from "crypto";
import db from "../../database";
import {
  shareEventTable,
  shareEventTypeEnum,
  sharedRecipeSaveTable,
  sharedRecipeTable,
} from "./share.table";
import { recipeTable } from "../recipe/recipe.table";

type SharedRecipe = typeof sharedRecipeTable.$inferSelect;
type SharedRecipeSave = typeof sharedRecipeSaveTable.$inferSelect;
type ShareEvent = typeof shareEventTable.$inferSelect;

const generateShareCode = (): string => {
  // 12-char URL-safe code
  return crypto.randomBytes(9).toString("base64url").slice(0, 12);
};

const findByRecipeId = async (
  recipeId: string,
): Promise<SharedRecipe | undefined> => {
  const [row] = await db
    .select()
    .from(sharedRecipeTable)
    .where(eq(sharedRecipeTable.recipeId, recipeId))
    .limit(1);

  return row;
};

const createForRecipe = async ({
  recipeId,
  userId,
}: {
  recipeId: string;
  userId: string;
}): Promise<SharedRecipe> => {
  let code = generateShareCode();

  // Basic collision retry loop
  // eslint-disable-next-line no-constant-condition
  while (true) {
    const [existing] = await db
      .select()
      .from(sharedRecipeTable)
      .where(eq(sharedRecipeTable.shareCode, code))
      .limit(1);

    if (!existing) break;
    code = generateShareCode();
  }

  const [created] = await db
    .insert(sharedRecipeTable)
    .values({
      recipeId,
      userId,
      shareCode: code,
    })
    .returning();

  return created;
};

const deactivate = async (recipeId: string, userId: string): Promise<void> => {
  await db
    .update(sharedRecipeTable)
    .set({ isActive: false })
    .where(
      and(
        eq(sharedRecipeTable.recipeId, recipeId),
        eq(sharedRecipeTable.userId, userId),
      ),
    );
};

const findByCode = async (
  code: string,
): Promise<(SharedRecipe & { recipe: typeof recipeTable.$inferSelect }) | null> => {
  const [row] = await db
    .select({
      shared: sharedRecipeTable,
      recipe: recipeTable,
    })
    .from(sharedRecipeTable)
    .innerJoin(
      recipeTable,
      eq(sharedRecipeTable.recipeId, recipeTable.id),
    )
    .where(eq(sharedRecipeTable.shareCode, code))
    .limit(1);

  if (!row) return null;

  return {
    ...(row.shared as SharedRecipe),
    recipe: row.recipe as typeof recipeTable.$inferSelect,
  };
};

const saveSubscription = async ({
  sharedRecipeId,
  userId,
}: {
  sharedRecipeId: string;
  userId: string;
}): Promise<SharedRecipeSave> => {
  const [existing] = await db
    .select()
    .from(sharedRecipeSaveTable)
    .where(
      and(
        eq(sharedRecipeSaveTable.sharedRecipeId, sharedRecipeId),
        eq(sharedRecipeSaveTable.userId, userId),
      ),
    )
    .limit(1);

  if (existing) return existing;

  const [created] = await db
    .insert(sharedRecipeSaveTable)
    .values({
      sharedRecipeId,
      userId,
    })
    .returning();

  return created;
};

const findSharedWithUser = async (userId: string) => {
  const rows = await db
    .select({
      shared: sharedRecipeTable,
      recipe: recipeTable,
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

  return rows;
};

const deleteSubscription = async (id: string, userId: string): Promise<void> => {
  await db
    .delete(sharedRecipeSaveTable)
    .where(
      and(
        eq(sharedRecipeSaveTable.id, id),
        eq(sharedRecipeSaveTable.userId, userId),
      ),
    );
};

const recordEvent = async ({
  sharedRecipeId,
  eventType,
  userId,
  metadata,
  ipHash,
}: {
  sharedRecipeId: string;
  eventType: (typeof shareEventTypeEnum)["enumValues"][number];
  userId?: string;
  metadata?: unknown;
  ipHash?: string;
}): Promise<ShareEvent> => {
  const [event] = await db
    .insert(shareEventTable)
    .values({
      sharedRecipeId,
      eventType,
      userId: userId ?? null,
      metadata: metadata ?? null,
      ipHash: ipHash ?? null,
    })
    .returning();

  return event;
};

const getStatsForRecipe = async (sharedRecipeId: string) => {
  const [row] = await db
    .select({
      webViews: count().filter(
        eq(shareEventTable.eventType, "web_view"),
      ),
      appOpens: count().filter(
        eq(shareEventTable.eventType, "app_open"),
      ),
      appInstalls: count().filter(
        eq(shareEventTable.eventType, "app_install"),
      ),
      recipeSaves: count().filter(
        eq(shareEventTable.eventType, "recipe_save"),
      ),
      groceryAdds: count().filter(
        eq(shareEventTable.eventType, "grocery_add"),
      ),
      groceryPurchases: count().filter(
        eq(shareEventTable.eventType, "grocery_purchase"),
      ),
    })
    .from(shareEventTable)
    .where(eq(shareEventTable.sharedRecipeId, sharedRecipeId));

  const [subs] = await db
    .select({ value: count() })
    .from(sharedRecipeSaveTable)
    .where(eq(sharedRecipeSaveTable.sharedRecipeId, sharedRecipeId));

  return {
    ...(row ?? {
      webViews: 0,
      appOpens: 0,
      appInstalls: 0,
      recipeSaves: 0,
      groceryAdds: 0,
      groceryPurchases: 0,
    }),
    subscriberCount: subs?.value ?? 0,
  };
};

export {
  createForRecipe,
  deactivate,
  deleteSubscription,
  findByCode,
  findByRecipeId,
  findSharedWithUser,
  getStatsForRecipe,
  recordEvent,
  saveSubscription,
};
export type { SharedRecipe, SharedRecipeSave, ShareEvent };

