import { logger } from "../../../logger";
import { Request, Response } from "express";
import * as cookbookRepository from "./cookbook.repository";
import * as recipeRepository from "../recipe/recipe.repository";
import type { Recipe } from "../recipe/recipe.repository";
import * as shareRepository from "../share/share.repository";

const formatRecipe = (recipe: Recipe) => ({
  id: recipe.id,
  name: recipe.name,
  description: recipe.description,
  ingredients: recipe.ingredients,
  instructions: JSON.parse(recipe.instructions),
  servings: recipe.servings,
  prepTimeMinutes: recipe.prepTimeMinutes,
  cookTimeMinutes: recipe.cookTimeMinutes,
  imageUrl: recipe.imageUrl,
  sourceUrl: recipe.sourceUrl ?? undefined,
  sourceTitle: recipe.sourceTitle ?? undefined,
  sourceAuthorName: recipe.sourceAuthorName ?? undefined,
  sourceAuthorAvatarUrl: recipe.sourceAuthorAvatarUrl ?? undefined,
});

const getCookbooks = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;

    const cookbooks = await cookbookRepository.findAllByUserId(userId);
    const cookbookIds = cookbooks.map((c) => c.id);

    const [recipeCounts, coverImages] = await Promise.all([
      cookbookRepository.getRecipeCountsByCookbookIds(cookbookIds),
      cookbookRepository.getCoverImagesByCookbookIds(cookbookIds),
    ]);

    // Compute virtual cookbook counts
    const ownedRecipes = await recipeRepository.findAllByUserId(userId);
    const sharedRecipes = await shareRepository.findSharedWithUser(userId);

    const allRecipesCount = ownedRecipes.length + sharedRecipes.length;
    const sharedWithMeCount = sharedRecipes.length;

    const formattedCookbooks = cookbooks.map((c) => ({
      id: c.id,
      name: c.name,
      description: c.description,
      coverImageUrl: c.coverImageUrl ?? coverImages.get(c.id) ?? null,
      recipeCount: recipeCounts.get(c.id) ?? 0,
    }));

    return res.status(200).json({
      cookbooks: formattedCookbooks,
      allRecipesCount,
      sharedWithMeCount,
    });
  } catch (error) {
    logger.error("Error fetching cookbooks:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to fetch cookbooks",
    });
  }
};

const createCookbook = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const { name, description } = req.body;

    if (!name || typeof name !== "string" || name.trim().length === 0) {
      return res.status(400).json({ error: "name is required" });
    }

    const cookbook = await cookbookRepository.create({
      userId,
      name: name.trim(),
      description: description ?? null,
    });

    return res.status(201).json({
      cookbook: {
        id: cookbook.id,
        name: cookbook.name,
        description: cookbook.description,
        coverImageUrl: cookbook.coverImageUrl,
        recipeCount: 0,
      },
    });
  } catch (error) {
    logger.error("Error creating cookbook:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to create cookbook",
    });
  }
};

const updateCookbook = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const id = req.params.id as string;

    const cookbook = await cookbookRepository.findById(id);
    if (!cookbook) {
      return res.status(404).json({ error: "Cookbook not found" });
    }
    if (cookbook.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const { name, description } = req.body;
    const updateData: { name?: string; description?: string | null } = {};
    if (name !== undefined) updateData.name = name.trim();
    if (description !== undefined) updateData.description = description;

    const updated = await cookbookRepository.update(id, updateData);

    const [recipeCounts, coverImages] = await Promise.all([
      cookbookRepository.getRecipeCountsByCookbookIds([id]),
      cookbookRepository.getCoverImagesByCookbookIds([id]),
    ]);

    return res.status(200).json({
      cookbook: {
        id: updated.id,
        name: updated.name,
        description: updated.description,
        coverImageUrl: updated.coverImageUrl ?? coverImages.get(id) ?? null,
        recipeCount: recipeCounts.get(id) ?? 0,
      },
    });
  } catch (error) {
    logger.error("Error updating cookbook:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to update cookbook",
    });
  }
};

const deleteCookbook = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const id = req.params.id as string;

    const cookbook = await cookbookRepository.findById(id);
    if (!cookbook) {
      return res.status(404).json({ error: "Cookbook not found" });
    }
    if (cookbook.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await cookbookRepository.deleteById(id);
    return res.status(200).json({ message: "Cookbook deleted" });
  } catch (error) {
    logger.error("Error deleting cookbook:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to delete cookbook",
    });
  }
};

const getCookbookRecipes = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const id = req.params.id as string;

    const cookbook = await cookbookRepository.findById(id);
    if (!cookbook) {
      return res.status(404).json({ error: "Cookbook not found" });
    }
    if (cookbook.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const recipes = await cookbookRepository.findRecipesByCookbookId(id);

    return res.status(200).json({
      recipes: recipes.map((r) => formatRecipe(r)),
    });
  } catch (error) {
    logger.error("Error fetching cookbook recipes:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to fetch cookbook recipes",
    });
  }
};

const addRecipesToCookbook = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const id = req.params.id as string;
    const { recipeIds } = req.body;

    if (!Array.isArray(recipeIds) || recipeIds.length === 0) {
      return res.status(400).json({ error: "recipeIds array is required" });
    }

    const cookbook = await cookbookRepository.findById(id);
    if (!cookbook) {
      return res.status(404).json({ error: "Cookbook not found" });
    }
    if (cookbook.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await cookbookRepository.addRecipesToCookbook(id, recipeIds);

    return res.status(200).json({ message: "Recipes added to cookbook" });
  } catch (error) {
    logger.error("Error adding recipes to cookbook:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to add recipes to cookbook",
    });
  }
};

const removeRecipeFromCookbook = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const cookbookId = req.params.id as string;
    const recipeId = req.params.recipeId as string;

    const cookbook = await cookbookRepository.findById(cookbookId);
    if (!cookbook) {
      return res.status(404).json({ error: "Cookbook not found" });
    }
    if (cookbook.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await cookbookRepository.removeRecipeFromCookbook(cookbookId, recipeId);

    return res.status(200).json({ message: "Recipe removed from cookbook" });
  } catch (error) {
    logger.error("Error removing recipe from cookbook:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to remove recipe from cookbook",
    });
  }
};

export default {
  getCookbooks,
  createCookbook,
  updateCookbook,
  deleteCookbook,
  getCookbookRecipes,
  addRecipesToCookbook,
  removeRecipeFromCookbook,
};
