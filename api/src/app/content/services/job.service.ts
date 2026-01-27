import { logger } from "../../../../logger";
import { detectContentSource } from "./content-detector.service";
import { parseYouTubeContent, isLongVideo } from "./youtube.service";
import { parseTikTokContent, isLongTikTokVideo } from "./tiktok.service";
import { parseWebsiteContent } from "./website.service";
import { extractFramesFromUrl, downloadImageAsBase64 } from "./frame-extractor.service";
import { filterFoodFrames, selectBestFoodFrames } from "./food-detection.service";
import {
  generateRecipeFromContent,
  GeneratedRecipe,
} from "./recipe-generator.service";

interface JobResult {
  recipe: GeneratedRecipe;
  contentId?: string;
}

interface JobStatus {
  jobId: string;
  status: "pending" | "processing" | "completed" | "failed";
  progress: number;
  result?: JobResult;
  error?: string;
}

const jobStore = new Map<string, JobStatus>();

function generateJobId(): string {
  return `job_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
}

function getJobStatus(jobId: string): JobStatus | undefined {
  return jobStore.get(jobId);
}

function updateJobStatus(
  jobId: string,
  updates: Partial<Omit<JobStatus, "jobId">>
): void {
  const current = jobStore.get(jobId);
  if (current) {
    jobStore.set(jobId, { ...current, ...updates });
  }
}

async function processContentAsync(
  jobId: string,
  url: string
): Promise<void> {
  try {
    updateJobStatus(jobId, { status: "processing", progress: 10 });

    const contentInfo = detectContentSource(url);
    let recipe: GeneratedRecipe;

    switch (contentInfo.source) {
      case "youtube": {
        if (!contentInfo.videoId) {
          throw new Error("Invalid YouTube URL");
        }

        updateJobStatus(jobId, { progress: 30 });
        const youtubeContent = await parseYouTubeContent(contentInfo.videoId);

        updateJobStatus(jobId, { progress: 70 });
        recipe = await generateRecipeFromContent({
          transcript: youtubeContent.transcript,
          sourceTitle: youtubeContent.metadata.title,
          sourceDescription: youtubeContent.metadata.description,
        });
        break;
      }

      case "tiktok": {
        updateJobStatus(jobId, { progress: 20 });
        const tiktokContent = await parseTikTokContent(url);

        if (tiktokContent.videoUrl) {
          updateJobStatus(jobId, { progress: 40 });
          const frames = await extractFramesFromUrl(tiktokContent.videoUrl, {
            intervalSeconds: 2,
            maxFrames: 10,
          });

          updateJobStatus(jobId, { progress: 60 });
          const foodFrames = await filterFoodFrames(frames);
          const bestFrames = await selectBestFoodFrames(foodFrames);

          updateJobStatus(jobId, { progress: 80 });
          recipe = await generateRecipeFromContent({
            transcript: tiktokContent.transcript,
            foodFrames: bestFrames,
            sourceTitle: tiktokContent.metadata.title,
            sourceDescription: tiktokContent.metadata.description,
          });
        } else {
          throw new Error("Could not extract TikTok video URL");
        }
        break;
      }

      case "website": {
        updateJobStatus(jobId, { progress: 30 });
        const websiteContent = await parseWebsiteContent(url);

        updateJobStatus(jobId, { progress: 60 });
        recipe = await generateRecipeFromContent({
          websiteContent: {
            mainContent: websiteContent.mainContent,
            recipeSchema: websiteContent.recipeSchema,
          },
          sourceTitle: websiteContent.title,
          sourceDescription: websiteContent.description,
        });
        break;
      }

      case "image": {
        updateJobStatus(jobId, { progress: 30 });
        const imageBase64 = await downloadImageAsBase64(url);

        updateJobStatus(jobId, { progress: 60 });
        recipe = await generateRecipeFromContent({
          imageBase64,
        });
        break;
      }

      default:
        throw new Error(`Unsupported content source: ${contentInfo.source}`);
    }

    updateJobStatus(jobId, {
      status: "completed",
      progress: 100,
      result: { recipe },
    });
  } catch (error) {
    logger.error(`Job ${jobId} failed:`, error);
    updateJobStatus(jobId, {
      status: "failed",
      error: error instanceof Error ? error.message : "Unknown error",
    });
  }
}

function startAsyncJob(url: string): string {
  const jobId = generateJobId();

  jobStore.set(jobId, {
    jobId,
    status: "pending",
    progress: 0,
  });

  setImmediate(() => {
    processContentAsync(jobId, url).catch((error) => {
      logger.error(`Async job ${jobId} error:`, error);
    });
  });

  return jobId;
}

async function shouldProcessAsync(url: string): Promise<boolean> {
  const contentInfo = detectContentSource(url);

  if (contentInfo.source === "website" || contentInfo.source === "image") {
    return false;
  }

  if (contentInfo.source === "youtube" && contentInfo.videoId) {
    try {
      const { getYouTubeMetadata } = await import("./youtube.service");
      const metadata = await getYouTubeMetadata(contentInfo.videoId);
      return isLongVideo(metadata.durationSeconds);
    } catch {
      return true;
    }
  }

  if (contentInfo.source === "tiktok") {
    try {
      const tiktokContent = await parseTikTokContent(url);
      return isLongTikTokVideo(tiktokContent.metadata.durationSeconds);
    } catch {
      return true;
    }
  }

  return false;
}

function cleanupOldJobs(): void {
  const oneHourAgo = Date.now() - 60 * 60 * 1000;

  for (const [jobId, job] of jobStore.entries()) {
    const timestamp = parseInt(jobId.split("_")[1] || "0", 10);
    if (timestamp < oneHourAgo) {
      jobStore.delete(jobId);
    }
  }
}

setInterval(cleanupOldJobs, 15 * 60 * 1000);

export {
  startAsyncJob,
  getJobStatus,
  shouldProcessAsync,
  processContentAsync,
  JobResult,
  JobStatus,
};
