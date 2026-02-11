import { Router } from "express";
import recipeController from "./recipe.controller";
import chatController from "../chat/chat.controller";

const router = Router();

router.post("/", recipeController.saveRecipe);
router.get("/", recipeController.getRecipes);
router.get("/pantry-recommendations", recipeController.getPantryRecommendations);
router.get("/:id", recipeController.getRecipeById);
router.put("/:id", recipeController.updateRecipe);
router.post("/:id/match-pantry", recipeController.matchPantry);
router.patch("/:id/ingredients/:index", recipeController.toggleIngredient);
router.get("/:id/nutrition", recipeController.getNutrition);
router.delete("/:id", recipeController.deleteRecipe);

// Chat
router.get("/:id/chat", chatController.getChatHistory);
router.post("/:id/chat", chatController.sendMessage);

export default router;
