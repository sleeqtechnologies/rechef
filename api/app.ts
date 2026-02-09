import express from "express";
import cors from "cors";
import apiRoutes from "./api.routes";
import { env } from "./env_config";
import { logger } from "./logger";
import { verifyUserToken } from "./src/auth";
import { failStaleJobs } from "./src/app/content/content.repository";

const app = express();
const port = env.PORT;

app.use(cors());
app.use(express.json());
app.use("/api", verifyUserToken, apiRoutes);

app.listen(port, async () => {
  logger.info(`Server is running at http://localhost:${port}`);

  const failed = await failStaleJobs();
  if (failed > 0) {
    logger.info(`Recovered ${failed} stale job(s) from previous crash`);
  }
});

export default app;
