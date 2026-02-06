import { eq, desc, and, inArray } from "drizzle-orm";
import db from "../../database";
import { savedContentTable, contentJobTable } from "./content.table";
import { recipeTable } from "../recipe/recipe.table";

type SavedContent = typeof savedContentTable.$inferSelect;
type NewSavedContent = typeof savedContentTable.$inferInsert;
type ContentJob = typeof contentJobTable.$inferSelect;
type NewContentJob = typeof contentJobTable.$inferInsert;

const createSavedContent = async (
  data: NewSavedContent
): Promise<SavedContent> => {
  const [content] = await db
    .insert(savedContentTable)
    .values(data)
    .returning();
  return content;
};

const createContentJob = async (data: NewContentJob): Promise<ContentJob> => {
  const [job] = await db.insert(contentJobTable).values(data).returning();
  return job;
};

const updateJobStatus = async (
  jobId: string,
  status: "pending" | "processing" | "completed" | "failed",
  extra?: { progress?: number; result?: unknown; error?: string }
): Promise<ContentJob> => {
  const [job] = await db
    .update(contentJobTable)
    .set({ status, ...extra })
    .where(eq(contentJobTable.id, jobId))
    .returning();
  return job;
};

const updateSavedContentStatus = async (
  contentId: string,
  status: "pending" | "processed" | "failed"
): Promise<void> => {
  await db
    .update(savedContentTable)
    .set({ status })
    .where(eq(savedContentTable.id, contentId));
};

const findJobsByUserId = async (
  userId: string,
  statuses?: string[]
): Promise<ContentJob[]> => {
  const conditions = [eq(contentJobTable.userId, userId)];

  if (statuses && statuses.length > 0) {
    conditions.push(
      inArray(
        contentJobTable.status,
        statuses as ("pending" | "processing" | "completed" | "failed")[]
      )
    );
  }

  return db
    .select()
    .from(contentJobTable)
    .where(and(...conditions))
    .orderBy(desc(contentJobTable.createdAt));
};

const findJobById = async (
  jobId: string
): Promise<ContentJob | undefined> => {
  const [job] = await db
    .select()
    .from(contentJobTable)
    .where(eq(contentJobTable.id, jobId))
    .limit(1);
  return job;
};

const findJobWithRecipe = async (jobId: string) => {
  const [job] = await db
    .select()
    .from(contentJobTable)
    .where(eq(contentJobTable.id, jobId))
    .limit(1);

  if (!job) return undefined;

  let recipe = undefined;
  if (job.status === "completed" && job.savedContentId) {
    const [r] = await db
      .select()
      .from(recipeTable)
      .where(eq(recipeTable.savedContentId, job.savedContentId))
      .limit(1);
    recipe = r;
  }

  return { job, recipe };
};

const findJobsWithRecipes = async (
  userId: string,
  statuses?: string[]
) => {
  const jobs = await findJobsByUserId(userId, statuses);

  const completedJobs = jobs.filter(
    (j) => j.status === "completed" && j.savedContentId
  );
  const contentIds = completedJobs
    .map((j) => j.savedContentId!)
    .filter(Boolean);

  let recipes: (typeof recipeTable.$inferSelect)[] = [];
  if (contentIds.length > 0) {
    recipes = await db
      .select()
      .from(recipeTable)
      .where(inArray(recipeTable.savedContentId, contentIds));
  }

  const recipeByContentId = new Map(
    recipes.map((r) => [r.savedContentId, r])
  );

  return jobs.map((job) => ({
    job,
    recipe: job.savedContentId
      ? recipeByContentId.get(job.savedContentId)
      : undefined,
  }));
};

export {
  createSavedContent,
  createContentJob,
  updateJobStatus,
  updateSavedContentStatus,
  findJobsByUserId,
  findJobById,
  findJobWithRecipe,
  findJobsWithRecipes,
};
export type { SavedContent, NewSavedContent, ContentJob, NewContentJob };
