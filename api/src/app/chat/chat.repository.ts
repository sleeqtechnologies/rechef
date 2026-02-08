import { eq, and, asc, desc } from "drizzle-orm";
import db from "../../database";
import { chatMessageTable } from "./chat.table";

type ChatMessage = typeof chatMessageTable.$inferSelect;
type NewChatMessage = typeof chatMessageTable.$inferInsert;

const findByRecipeAndUser = async (
  recipeId: string,
  userId: string,
): Promise<ChatMessage[]> => {
  return db
    .select()
    .from(chatMessageTable)
    .where(
      and(
        eq(chatMessageTable.recipeId, recipeId),
        eq(chatMessageTable.userId, userId),
      ),
    )
    .orderBy(asc(chatMessageTable.createdAt));
};

const findRecentByRecipeAndUser = async (
  recipeId: string,
  userId: string,
  limit = 20,
): Promise<ChatMessage[]> => {
  // Get the last N messages (descending), then reverse for chronological order
  const messages = await db
    .select()
    .from(chatMessageTable)
    .where(
      and(
        eq(chatMessageTable.recipeId, recipeId),
        eq(chatMessageTable.userId, userId),
      ),
    )
    .orderBy(desc(chatMessageTable.createdAt))
    .limit(limit);

  return messages.reverse();
};

const create = async (data: NewChatMessage): Promise<ChatMessage> => {
  const [message] = await db
    .insert(chatMessageTable)
    .values(data)
    .returning();

  return message;
};

export { findByRecipeAndUser, findRecentByRecipeAndUser, create };
export type { ChatMessage, NewChatMessage };
