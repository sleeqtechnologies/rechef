import { logger } from "../../../logger";
import { Request, Response } from "express";
import * as recipeRepository from "./recipe.repository";
import type { Recipe } from "./recipe.repository";

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

    return res.status(200).json({ recipes: recipes.map(formatRecipe) });
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
    const { id } = req.params;
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

const deleteRecipe = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
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

export default { saveRecipe, getRecipes, getRecipeById, deleteRecipe };
