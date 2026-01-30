import { eq } from "drizzle-orm";
import db from "../../database";
import { userTable } from "./user.table";

type User = typeof userTable.$inferSelect;

const findOrCreateByFirebaseUid = async ({
  firebaseAuthUid,
  name,
  email,
}: {
  firebaseAuthUid: string;
  name: string;
  email: string;
}): Promise<User> => {
  const [existingUser] = await db
    .select()
    .from(userTable)
    .where(eq(userTable.firebaseAuthUid, firebaseAuthUid))
    .limit(1);

  if (existingUser) {
    return existingUser;
  }

  const [createdUser] = await db
    .insert(userTable)
    .values({
      firebaseAuthUid,
      name,
      email,
    })
    .returning();

  return createdUser;
};

export { findOrCreateByFirebaseUid };
export type { User };
