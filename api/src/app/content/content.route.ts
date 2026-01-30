import { Router } from "express";
import contentController from "./content.controller";

const router = Router();

router.post("/parse", contentController.parseContent);

export default router;
