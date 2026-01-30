import { NextFunction, Request, Response } from "express";
import admin from "./services/firebase";
import { logger } from "../logger";
import { env } from "../env_config";
import { findOrCreateByFirebaseUid } from "./app/user/user.repository";

const verifyUserToken = async (
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  const idToken = req.headers.authorization?.split("Bearer ")[1];

  if (!idToken) {
    logger.error("Provide authorization token");
    res.status(401).json({ message: "Provide authorization token" });
    return;
  }

  env.isDevelopment ? logger.debug(idToken) : logger.debug("Got token");

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    const firebaseAuthUid = decodedToken.uid;

    if (!decodedToken.email) {
      logger.info(`Anonymous user detected ${firebaseAuthUid}`);
    }

    const user = await findOrCreateByFirebaseUid({
      firebaseAuthUid,
      name: decodedToken.name ?? "Anonymous",
      email: decodedToken.email ?? `${firebaseAuthUid}@anonymous.local`,
    });

    req.user = user;
    next();
  } catch (error) {
    logger.error("Error verifying token", error);
    res.status(401).json({ message: "Unauthorized" });
  }
};

export { verifyUserToken };
