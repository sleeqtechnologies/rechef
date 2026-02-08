import { Router } from "express";
import recipeController from "./recipe.controller";

const router = Router();

router.post("/", recipeController.saveRecipe);
router.get("/", recipeController.getRecipes);
router.get("/:id", recipeController.getRecipeById);
router.post("/:id/match-pantry", recipeController.matchPantry);
router.patch("/:id/ingredients/:index", recipeController.toggleIngredient);
router.delete("/:id", recipeController.deleteRecipe);

export default router;
