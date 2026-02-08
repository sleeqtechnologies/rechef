import express from "express";
import cors from "cors";
import apiRoutes from "./api.routes";
import { env } from "./env_config";
import { logger } from "./logger";
import { verifyUserToken } from "./src/auth";

const app = express();
const port = env.PORT;

app.use(cors());
app.use(express.json());
app.use("/api", verifyUserToken, apiRoutes);

if (!process.env.VERCEL) {
  app.listen(port, () => {
    logger.info(`Server is running at http://localhost:${port}`);
  });
}

export default app;
