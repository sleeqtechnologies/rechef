import { Router } from "express";
import groceryController from "./grocery.controller";

const router = Router();

router.post("/", groceryController.addItems);
router.post("/order", groceryController.createOrder);
router.get("/", groceryController.getItems);
router.patch("/:itemId", groceryController.toggleItem);
router.delete("/checked", groceryController.clearChecked);
router.delete("/:itemId", groceryController.deleteItem);

export default router;
