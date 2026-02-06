import { Router } from "express";
import recipeController from "./recipe.controller";

const router = Router();

router.post("/", recipeController.saveRecipe);
router.get("/", recipeController.getRecipes);
router.get("/:id", recipeController.getRecipeById);
router.delete("/:id", recipeController.deleteRecipe);

export default router;
