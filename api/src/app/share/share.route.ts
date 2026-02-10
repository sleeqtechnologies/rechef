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

const shareApiRouter = Router();

shareApiRouter.post("/recipes/:id/share", createOrGetShareLink);
shareApiRouter.delete("/recipes/:id/share", deactivateShareLink);
shareApiRouter.get("/recipes/:id/share/stats", getShareStats);
shareApiRouter.get("/shared-with-me", getSharedWithMe);
shareApiRouter.post("/shared-with-me/:code", saveSharedRecipe);
shareApiRouter.delete("/shared-with-me/:id", removeSharedRecipe);

const sharePublicRouter = Router();

sharePublicRouter.get("/share/:code", getSharedRecipePublic);
sharePublicRouter.post("/share/:code/events", recordShareEventPublic);

export { shareApiRouter, sharePublicRouter };

