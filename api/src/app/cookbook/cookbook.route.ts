import { Router } from "express";
import cookbookController from "./cookbook.controller";

const router = Router();

router.get("/", cookbookController.getCookbooks);
router.post("/", cookbookController.createCookbook);
router.get("/by-recipe/:recipeId", cookbookController.getCookbooksForRecipe);
router.put("/:id", cookbookController.updateCookbook);
router.delete("/:id", cookbookController.deleteCookbook);
router.get("/:id/recipes", cookbookController.getCookbookRecipes);
router.post("/:id/recipes", cookbookController.addRecipesToCookbook);
router.delete("/:id/recipes/:recipeId", cookbookController.removeRecipeFromCookbook);

export default router;
