import { logger } from "../../../logger";
import { Request, Response } from "express";
import * as recipeRepository from "./recipe.repository";
import * as pantryRepository from "../pantry/pantry.repository";
import { matchIngredientsWithPantry } from "../../services/pantry-matcher";
import type { Recipe } from "./recipe.repository";

interface IngredientJson {
  name: string;
  quantity: string;
  unit?: string;
  notes?: string;
  inPantry?: boolean;
}

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

const saveRecipe = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const {
      name,
      description,
      ingredients,
      instructions,
      servings,
      prepTimeMinutes,
      cookTimeMinutes,
      imageUrl,
      sourceUrl,
      sourceTitle,
      sourceAuthorName,
      sourceAuthorAvatarUrl,
    } = req.body;

    if (!name || !ingredients || !instructions) {
      return res
        .status(400)
        .json({ error: "name, ingredients, and instructions are required" });
    }

    const recipe = await recipeRepository.create({
      userId,
      name,
      description: description ?? "",
      ingredients,
      instructions: JSON.stringify(instructions),
      servings: servings ?? null,
      prepTimeMinutes: prepTimeMinutes ?? null,
      cookTimeMinutes: cookTimeMinutes ?? null,
      imageUrl: imageUrl ?? null,
      sourceUrl: sourceUrl ?? null,
      sourceTitle: sourceTitle ?? null,
      sourceAuthorName: sourceAuthorName ?? null,
      sourceAuthorAvatarUrl: sourceAuthorAvatarUrl ?? null,
    });

    return res.status(201).json({ recipe: formatRecipe(recipe) });
  } catch (error) {
    logger.error("Error saving recipe:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to save recipe",
    });
  }
};

const getRecipes = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const recipes = await recipeRepository.findAllByUserId(userId);

    return res.status(200).json({ recipes: recipes.map((r) => formatRecipe(r)) });
  } catch (error) {
    logger.error("Error fetching recipes:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to fetch recipes",
    });
  }
};

const getRecipeById = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const recipe = await recipeRepository.findById(id);

    if (!recipe) {
      return res.status(404).json({ error: "Recipe not found" });
    }

    if (recipe.userId !== req.user.id) {
      return res.status(403).json({ error: "Forbidden" });
    }

    return res.status(200).json({ recipe: formatRecipe(recipe) });
  } catch (error) {
    logger.error("Error fetching recipe:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to fetch recipe",
    });
  }
};

const matchPantry = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const recipe = await recipeRepository.findById(id);

    if (!recipe) {
      return res.status(404).json({ error: "Recipe not found" });
    }

    if (recipe.userId !== req.user.id) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const ingredients = recipe.ingredients as IngredientJson[];
    const pantryItems = await pantryRepository.findAllByUserId(req.user.id);

    if (pantryItems.length === 0) {
      return res.status(200).json({ ingredients });
    }

    // Only match ingredients that are currently unchecked
    const uncheckedIndices: number[] = [];
    const uncheckedNames: string[] = [];
    for (let i = 0; i < ingredients.length; i++) {
      if (!ingredients[i].inPantry) {
        uncheckedIndices.push(i);
        uncheckedNames.push(ingredients[i].name);
      }
    }

    if (uncheckedNames.length > 0) {
      const pantryNames = pantryItems.map((p) => p.name);
      const matched = await matchIngredientsWithPantry(
        uncheckedNames,
        pantryNames,
      );

      for (let ai = 0; ai < uncheckedIndices.length; ai++) {
        if (matched.has(ai)) {
          ingredients[uncheckedIndices[ai]].inPantry = true;
        }
      }
    }

    await recipeRepository.updateIngredients(id, ingredients);

    return res.status(200).json({ ingredients });
  } catch (error) {
    logger.error("Error matching pantry:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to match pantry",
    });
  }
};

const toggleIngredient = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const index = parseInt(req.params.index as string, 10);
    const recipe = await recipeRepository.findById(id);

    if (!recipe) {
      return res.status(404).json({ error: "Recipe not found" });
    }

    if (recipe.userId !== req.user.id) {
      return res.status(403).json({ error: "Forbidden" });
    }

    const ingredients = recipe.ingredients as IngredientJson[];

    if (isNaN(index) || index < 0 || index >= ingredients.length) {
      return res.status(400).json({ error: "Invalid ingredient index" });
    }

    ingredients[index].inPantry = !ingredients[index].inPantry;

    await recipeRepository.updateIngredients(id, ingredients);

    return res.status(200).json({ ingredient: ingredients[index] });
  } catch (error) {
    logger.error("Error toggling ingredient:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to toggle ingredient",
    });
  }
};

const deleteRecipe = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const recipe = await recipeRepository.findById(id);

    if (!recipe) {
      return res.status(404).json({ error: "Recipe not found" });
    }

    if (recipe.userId !== req.user.id) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await recipeRepository.deleteById(id);
    return res.status(200).json({ message: "Recipe deleted" });
  } catch (error) {
    logger.error("Error deleting recipe:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to delete recipe",
    });
  }
};

export default {
  saveRecipe,
  getRecipes,
  getRecipeById,
  matchPantry,
  toggleIngredient,
  deleteRecipe,
};
