import { cleanEnv, num, str } from "envalid";
import dotenv from "dotenv";

dotenv.config();

const env = cleanEnv(process.env, {
  PORT: num({ default: 1234 }),
  NODE_ENV: str({ choices: ["development", "production"], default: "production" }),
  DATABASE_URL: str(),
  OPENAI_API_KEY: str(),
  SERVICE_ACCT_KEY: str(),
  UNSPLASH_ACCESS_KEY: str(),
  INSTACART_API_KEY: str(),
});

export { env };
