import { Router } from "express";
import contentController from "./content.controller";

const router = Router();

router.post("/parse", contentController.parseContent);
router.get("/job/:jobId", contentController.checkJobStatus);

export default router;
