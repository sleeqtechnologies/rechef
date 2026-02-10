import { Router } from "express";
import {
  createOrGetShareLink,
  deactivateShareLink,
  getShareStats,
  getSharedRecipePublic,
  recordShareEventPublic,
  getSharedWithMe,
  saveSharedRecipe,
  removeSharedRecipe,
} from "./share.controller";

// Authenticated routes mounted under /api
const shareApiRouter = Router();

shareApiRouter.post("/api/recipes/:id/share", createOrGetShareLink);
shareApiRouter.delete("/api/recipes/:id/share", deactivateShareLink);
shareApiRouter.get("/api/recipes/:id/share/stats", getShareStats);
shareApiRouter.get("/api/shared-with-me", getSharedWithMe);
shareApiRouter.post("/api/shared-with-me/:code", saveSharedRecipe);
shareApiRouter.delete("/api/shared-with-me/:id", removeSharedRecipe);

// Public routes mounted at root
const sharePublicRouter = Router();

sharePublicRouter.get("/share/:code", getSharedRecipePublic);
sharePublicRouter.post("/share/:code/events", recordShareEventPublic);

export { shareApiRouter, sharePublicRouter };

