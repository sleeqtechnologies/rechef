import { cleanEnv, num, str } from "envalid";
import dotenv from "dotenv";

dotenv.config();

const env = cleanEnv(process.env, {
  PORT: num({ default: 1234 }),
  NODE_ENV: str({ choices: ["development", "production"] }),
  DATABASE_URL: str(),
  OPENAI_API_KEY: str(),
  SERVICE_ACCT_KEY: str(),
});

export { env };
