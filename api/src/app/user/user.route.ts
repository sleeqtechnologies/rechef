import { Router } from "express";
import userController from "./user.controller";

const router = Router();

router.post("/", userController.createUser);
router.post("/onboarding", userController.saveOnboardingData);

export default router;
