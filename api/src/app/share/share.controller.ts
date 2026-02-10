import { Request, Response } from "express";
import { logger } from "../../../logger";
import * as shareRepository from "./share.repository";
import * as recipeRepository from "../recipe/recipe.repository";

const formatSharedRecipeResponse = (data: {
  recipe: recipeRepository.Recipe;
  creatorId: string;
  shareCode: string;
}) => ({
  recipe: {
    id: data.recipe.id,
    name: data.recipe.name,
    description: data.recipe.description,
    ingredients: data.recipe.ingredients,
    instructions: JSON.parse(data.recipe.instructions),
    servings: data.recipe.servings,
    prepTimeMinutes: data.recipe.prepTimeMinutes,
    cookTimeMinutes: data.recipe.cookTimeMinutes,
    imageUrl: data.recipe.imageUrl,
    sourceUrl: data.recipe.sourceUrl ?? undefined,
    sourceTitle: data.recipe.sourceTitle ?? undefined,
    sourceAuthorName: data.recipe.sourceAuthorName ?? undefined,
    sourceAuthorAvatarUrl: data.recipe.sourceAuthorAvatarUrl ?? undefined,
  },
  creatorId: data.creatorId,
  shareCode: data.shareCode,
});

// POST /api/recipes/:id/share
const createOrGetShareLink = async (req: Request, res: Response) => {
  try {
    const recipeId = req.params.id as string;
    const userId = req.user.id as string;

    const recipe = await recipeRepository.findById(recipeId);
    if (!recipe) {
      return res.status(404).json({ error: "Recipe not found" });
    }
    if (recipe.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    let shared = await shareRepository.findByRecipeId(recipeId);

    if (!shared || !shared.isActive) {
      shared = await shareRepository.createForRecipe({
        recipeId,
        userId,
      });
    }

    return res.status(200).json({
      shareCode: shared.shareCode,
      url: `https://rechef-ten.vercel.app/recipe/${shared.shareCode}`,
    });
  } catch (error) {
    logger.error("Error creating share link:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to create share link",
    });
  }
};

// DELETE /api/recipes/:id/share
const deactivateShareLink = async (req: Request, res: Response) => {
  try {
    const recipeId = req.params.id as string;
    const userId = req.user.id as string;

    const recipe = await recipeRepository.findById(recipeId);
    if (!recipe) {
      return res.status(404).json({ error: "Recipe not found" });
    }
    if (recipe.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await shareRepository.deactivate(recipeId, userId);
    return res.status(200).json({ success: true });
  } catch (error) {
    logger.error("Error deactivating share link:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to deactivate share link",
    });
  }
};

// GET /api/recipes/:id/share/stats
const getShareStats = async (req: Request, res: Response) => {
  try {
    const recipeId = req.params.id as string;
    const userId = req.user.id as string;

    const recipe = await recipeRepository.findById(recipeId);
    if (!recipe) {
      return res.status(404).json({ error: "Recipe not found" });
    }
    if (recipe.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const shared = await shareRepository.findByRecipeId(recipeId);
    if (!shared) {
      return res.status(200).json({
        stats: {
          webViews: 0,
          appOpens: 0,
          appInstalls: 0,
          recipeSaves: 0,
          groceryAdds: 0,
          groceryPurchases: 0,
          subscriberCount: 0,
        },
      });
    }

    const stats = await shareRepository.getStatsForRecipe(shared.id);
    return res.status(200).json({ stats });
  } catch (error) {
    logger.error("Error fetching share stats:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to fetch share stats",
    });
  }
};

// GET /share/:code (public)
const getSharedRecipePublic = async (req: Request, res: Response) => {
  try {
    const code = req.params.code as string;
    const shared = await shareRepository.findByCode(code);

    if (!shared || !shared.isActive) {
      return res.status(404).json({ error: "Shared recipe not found" });
    }

    const response = formatSharedRecipeResponse({
      recipe: shared.recipe,
      creatorId: shared.userId,
      shareCode: shared.shareCode,
    });

    return res.status(200).json(response);
  } catch (error) {
    logger.error("Error fetching shared recipe:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to fetch shared recipe",
    });
  }
};

// POST /share/:code/events (public)
const recordShareEventPublic = async (req: Request, res: Response) => {
  try {
    const code = req.params.code as string;
    const { eventType, metadata } = req.body as {
      eventType: string;
      metadata?: unknown;
    };

    const shared = await shareRepository.findByCode(code);
    if (!shared || !shared.isActive) {
      return res.status(404).json({ error: "Shared recipe not found" });
    }

    if (
      ![
        "web_view",
        "app_open",
        "app_install",
        "recipe_save",
        "grocery_add",
        "grocery_purchase",
      ].includes(eventType)
    ) {
      return res.status(400).json({ error: "Invalid event type" });
    }

    // Basic IP hash for anonymous dedup; best-effort only
    const ip =
      (req.headers["x-forwarded-for"] as string | undefined)
        ?.split(",")[0]
        ?.trim() ??
      req.socket.remoteAddress ??
      "";
    const ipHash = ip ? Buffer.from(ip).toString("base64url") : undefined;

    await shareRepository.recordEvent({
      sharedRecipeId: shared.id,
      eventType: eventType as any,
      metadata,
      ipHash,
    });

    return res.status(201).json({ success: true });
  } catch (error) {
    logger.error("Error recording share event:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to record share event",
    });
  }
};

// GET /api/shared-with-me
const getSharedWithMe = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id as string;
    const sharedRecipes = await shareRepository.findSharedWithUser(userId);

    const formatted = sharedRecipes.map((row) => ({
      id: row.save.id,
      recipe: {
        id: row.recipe.id,
        name: row.recipe.name,
        description: row.recipe.description,
        ingredients: row.recipe.ingredients,
        instructions: JSON.parse(row.recipe.instructions),
        servings: row.recipe.servings,
        prepTimeMinutes: row.recipe.prepTimeMinutes,
        cookTimeMinutes: row.recipe.cookTimeMinutes,
        imageUrl: row.recipe.imageUrl,
        sourceUrl: row.recipe.sourceUrl ?? undefined,
        sourceTitle: row.recipe.sourceTitle ?? undefined,
        sourceAuthorName: row.recipe.sourceAuthorName ?? undefined,
        sourceAuthorAvatarUrl: row.recipe.sourceAuthorAvatarUrl ?? undefined,
      },
      shareCode: row.shared.shareCode,
      createdAt: row.shared.createdAt,
    }));

    return res.status(200).json({ recipes: formatted });
  } catch (error) {
    logger.error("Error fetching shared-with-me recipes:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to fetch shared recipes",
    });
  }
};

// POST /api/shared-with-me/:code
const saveSharedRecipe = async (req: Request, res: Response) => {
  try {
    const code = req.params.code as string;
    const userId = req.user.id as string;

    const shared = await shareRepository.findByCode(code);
    if (!shared || !shared.isActive) {
      return res.status(404).json({ error: "Shared recipe not found" });
    }

    // Don't allow saving your own shared recipe
    if (shared.userId === userId) {
      return res.status(400).json({
        error: "Cannot save your own shared recipe",
      });
    }

    const subscription = await shareRepository.saveSubscription({
      sharedRecipeId: shared.id,
      userId,
    });

    // Record recipe_save event
    await shareRepository.recordEvent({
      sharedRecipeId: shared.id,
      eventType: "recipe_save",
      userId,
    });

    return res.status(201).json({
      id: subscription.id,
      shareCode: shared.shareCode,
      recipe: formatSharedRecipeResponse({
        recipe: shared.recipe,
        creatorId: shared.userId,
        shareCode: shared.shareCode,
      }).recipe,
    });
  } catch (error) {
    logger.error("Error saving shared recipe:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to save shared recipe",
    });
  }
};

const removeSharedRecipe = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const userId = req.user.id as string;

    await shareRepository.deleteSubscription(id, userId);
    return res.status(200).json({ success: true });
  } catch (error) {
    logger.error("Error removing shared recipe:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to remove shared recipe",
    });
  }
};

export {
  createOrGetShareLink,
  deactivateShareLink,
  getShareStats,
  getSharedRecipePublic,
  recordShareEventPublic,
  getSharedWithMe,
  saveSharedRecipe,
  removeSharedRecipe,
};
