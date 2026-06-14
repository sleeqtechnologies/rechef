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

const serviceAccount = getServiceAccount();
const projectId =
  serviceAccount.projectId ??
  (serviceAccount as admin.ServiceAccount & { project_id?: string }).project_id;

if (!projectId) {
  throw new Error("Firebase service account project ID is required");
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: env.FIREBASE_STORAGE_BUCKET || `${projectId}.firebasestorage.app`,
});

export default admin;
