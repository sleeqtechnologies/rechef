import admin from "firebase-admin";
import { env } from "../../env_config";

admin.initializeApp({
  credential: admin.credential.cert(env.SERVICE_ACCT_KEY),
});

export default admin;
