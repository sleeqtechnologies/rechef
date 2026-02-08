import { Router } from "express";
import chatController from "./chat.controller";

const router = Router();

// Chat routes are nested under /recipes/:id/chat
router.get("/:id/chat", chatController.getChatHistory);
router.post("/:id/chat", chatController.sendMessage);

export default router;
