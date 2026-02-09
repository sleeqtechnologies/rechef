import fs from "fs";
import path from "path";
import admin from "firebase-admin";
import { env } from "../../env_config";

function getServiceAccount(): admin.ServiceAccount {
  const raw = env.SERVICE_ACCT_KEY.trim();
  if (raw.startsWith(".") || raw.startsWith("/")) {
    const filePath = path.resolve(process.cwd(), raw);
    const json = fs.readFileSync(filePath, "utf-8");
    return JSON.parse(json) as admin.ServiceAccount;
  }
  return JSON.parse(raw) as admin.ServiceAccount;
}

admin.initializeApp({
  credential: admin.credential.cert(getServiceAccount()),
});

export default admin;
