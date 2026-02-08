import { Router } from "express";
import recipeRoutes from "./src/app/recipe/recipe.route";
import userRoutes from "./src/app/user/user.route";
import contentRoutes from "./src/app/content/content.route";
import pantryRoutes from "./src/app/pantry/pantry.route";

const router: Router = Router();

router.use("/contents", contentRoutes);
router.use("/recipes", recipeRoutes);
router.use("/users", userRoutes);
router.use("/pantry", pantryRoutes);

export default router;
