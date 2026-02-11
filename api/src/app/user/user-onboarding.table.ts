import { jsonb, pgTable, varchar } from "drizzle-orm/pg-core";
import { createdAt, dbId, updatedAt } from "../../database/shared-drizzle";

const userOnboardingTable = pgTable("user_onboarding", {
  id: dbId,
  firebaseAuthUid: varchar("firebase_auth_uid", { length: 255 }).notNull(),
  goals: jsonb("goals").$type<string[]>().default([]).notNull(),
  recipeSources: jsonb("recipe_sources")
    .$type<string[]>()
    .default([])
    .notNull(),
  organizationMethod: varchar("organization_method", { length: 100 }),
  createdAt,
  updatedAt,
});

export { userOnboardingTable };
