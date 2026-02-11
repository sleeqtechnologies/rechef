import { Request, Response } from "express";
import { eq } from "drizzle-orm";
import { logger } from "../../../logger";
import db from "../../database";
import { userOnboardingTable } from "./user-onboarding.table";

const createUser = async (req: Request, res: Response) => {
  logger.info("Creating user", { body: req.body });
  res.status(200).json({ message: "User created" });
};

const saveOnboardingData = async (req: Request, res: Response) => {
  const firebaseAuthUid = req.user.firebaseAuthUid;
  const { goals, recipeSources, organizationMethod } = req.body;

  try {
    // Upsert: check if onboarding data already exists for this user
    const [existing] = await db
      .select()
      .from(userOnboardingTable)
      .where(eq(userOnboardingTable.firebaseAuthUid, firebaseAuthUid))
      .limit(1);

    if (existing) {
      await db
        .update(userOnboardingTable)
        .set({
          goals: goals ?? [],
          recipeSources: recipeSources ?? [],
          organizationMethod: organizationMethod ?? null,
        })
        .where(eq(userOnboardingTable.firebaseAuthUid, firebaseAuthUid));
    } else {
      await db.insert(userOnboardingTable).values({
        firebaseAuthUid,
        goals: goals ?? [],
        recipeSources: recipeSources ?? [],
        organizationMethod: organizationMethod ?? null,
      });
    }

    res.status(200).json({ message: "Onboarding data saved" });
  } catch (error) {
    logger.error("Error saving onboarding data", { error });
    res.status(500).json({ message: "Failed to save onboarding data" });
  }
};

export default { createUser, saveOnboardingData };
