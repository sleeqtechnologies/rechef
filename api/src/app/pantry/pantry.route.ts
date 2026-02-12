import { Router } from "express";
import pantryController from "./pantry.controller";

const router = Router();

router.post("/", pantryController.addItems);
router.get("/", pantryController.getItems);
router.delete("/:id", pantryController.deleteItem);

const publicRouter = Router();
publicRouter.post("/pantry/images", pantryController.getImages);

export default router;
export { publicRouter as pantryPublicRouter };
