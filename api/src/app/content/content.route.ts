import { Router } from "express";
import contentController from "./content.controller";

const router = Router();

router.post("/parse", contentController.parseContent);
router.get("/jobs", contentController.getJobs);
router.get("/jobs/:jobId", contentController.getJobById);

export default router;
