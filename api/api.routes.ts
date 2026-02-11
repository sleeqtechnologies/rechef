import { Router } from "express";
import recipeRoutes from "./src/app/recipe/recipe.route";
import userRoutes from "./src/app/user/user.route";
import contentRoutes from "./src/app/content/content.route";
import pantryRoutes from "./src/app/pantry/pantry.route";
import groceryRoutes from "./src/app/grocery/grocery.route";
import cookbookRoutes from "./src/app/cookbook/cookbook.route";
import { shareApiRouter } from "./src/app/share/share.route";

const router: Router = Router();

router.use("/contents", contentRoutes);
router.use("/recipes", recipeRoutes);
router.use("/users", userRoutes);
router.use("/pantry", pantryRoutes);
router.use("/grocery", groceryRoutes);
router.use("/cookbooks", cookbookRoutes);
router.use("/", shareApiRouter);

export default router;
