import { logger } from "../../../logger";
import { Request, Response } from "express";
import { ParseContentSchema } from "./content.validation";
import {
  detectContentSource,
  ContentSource,
} from "../../services/content-detector";
import { parseYouTubeContent } from "../../services/youtube";
import { parseTikTokContent } from "../../services/tiktok";
import { parseInstagramContent } from "../../services/instagram";
import { parseFacebookContent } from "../../services/facebook";
import { parseWebsiteContent } from "../../services/website";
import {
  extractFramesFromUrl,
  downloadImageAsBase64,
  downloadVideo,
  extractFramesStreaming,
  cleanupTempDir,
  FrameExtractionOptions,
} from "../../services/frame-extractor";
import {
  filterFoodFrames,
  selectBestFoodFrames,
  detectFoodInFrame,
} from "../../services/food-detection";
import type { FrameWithFood } from "../../services/food-detection";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";
import type { GeneratedRecipe } from "../../services/recipe-generator";
import { generateRecipeFromContent } from "../../services/recipe-generator";
import * as contentRepo from "./content.repository";
import * as recipeRepo from "../recipe/recipe.repository";

interface GenerateRecipeResult {
  recipe: GeneratedRecipe;
  sourceUrl?: string | null;
  sourceTitle?: string | null;
  sourceAuthorName?: string | null;
  sourceAuthorAvatarUrl?: string | null;
  savedContentTitle?: string | null;
  savedContentThumbnailUrl?: string | null;
}

function contentSourceToType(
  source: ContentSource,
): "video" | "image" | "website" {
  switch (source) {
    case "youtube":
    case "tiktok":
    case "instagram":
    case "facebook":
      return "video";
    case "image":
      return "image";
    case "website":
      return "website";
  }
}

const parseContent = async (
  req: Request<{}, {}, ParseContentSchema>,
  res: Response,
) => {
  try {
    const { url, imageBase64 } = req.body;
    const userId = req.user.id;

    const sourceUrl = url || "image-upload";
    const contentType = url
      ? contentSourceToType(detectContentSource(url).source)
      : "image";

    const savedContent = await contentRepo.createSavedContent({
      userId,
      contentType,
      sourceUrl,
    });

    const job = await contentRepo.createContentJob({
      userId,
      savedContentId: savedContent.id,
      status: "pending",
    });

    res.status(202).json({
      jobId: job.id,
      savedContentId: savedContent.id,
    });

    processContentInBackground(
      job.id,
      savedContent.id,
      userId,
      { url, imageBase64 },
      {
        userName: req.user.name,
      },
    );
  } catch (error) {
    logger.error("Error initiating content parse:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to initiate content parsing",
    });
  }
};

async function processContentInBackground(
  jobId: string,
  savedContentId: string,
  userId: string,
  input: { url?: string; imageBase64?: string },
  options?: { userName?: string },
) {
  try {
    await contentRepo.updateJobStatus(jobId, "processing", { progress: 10 });

    const result = await generateRecipe(input, options);

    if (
      result.savedContentTitle != null ||
      result.savedContentThumbnailUrl != null
    ) {
      await contentRepo.updateSavedContentMetadata(savedContentId, {
        title: result.savedContentTitle ?? undefined,
        thumbnailUrl: result.savedContentThumbnailUrl ?? undefined,
      });
    }

    await contentRepo.updateJobStatus(jobId, "completed", { progress: 100 });
    await contentRepo.updateSavedContentStatus(savedContentId, "processed");

    const { recipe } = result;
    await recipeRepo.create({
      userId,
      savedContentId,
      name: recipe.name,
      description: recipe.description,
      ingredients: recipe.ingredients,
      instructions: JSON.stringify(recipe.instructions),
      servings: recipe.servings ?? null,
      prepTimeMinutes: recipe.prepTimeMinutes ?? null,
      cookTimeMinutes: recipe.cookTimeMinutes ?? null,
      imageUrl: recipe.imageUrl ?? null,
      sourceUrl: result.sourceUrl ?? null,
      sourceTitle: result.sourceTitle ?? null,
      sourceAuthorName: result.sourceAuthorName ?? null,
      sourceAuthorAvatarUrl: result.sourceAuthorAvatarUrl ?? null,
    });

    logger.info(`Job ${jobId} completed successfully`);
  } catch (error) {
    logger.error(`Job ${jobId} failed:`, error);
    await contentRepo.updateJobStatus(jobId, "failed", {
      error: error instanceof Error ? error.message : "Unknown error",
    });
    await contentRepo.updateSavedContentStatus(savedContentId, "failed");
  }
}

let processing = false;
const waitQueue: (() => void)[] = [];

async function acquireProcessingSlot(): Promise<void> {
  if (!processing) {
    processing = true;
    return;
  }
  return new Promise<void>((resolve) => {
    waitQueue.push(resolve);
  });
}

function releaseProcessingSlot(): void {
  const next = waitQueue.shift();
  if (next) {
    next();
  } else {
    processing = false;
  }
}

async function extractAndFilterFrames(
  videoUrl: string,
  options: FrameExtractionOptions,
): Promise<{ foodFrames: FrameWithFood[]; firstFrameBase64: string | undefined }> {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "video-"));
  const videoPath = path.join(tempDir, "video.mp4");

  try {
    await downloadVideo(videoUrl, videoPath);

    let firstFrameBase64: string | undefined;
    const foodFrames = await extractFramesStreaming<FrameWithFood>(
      videoPath,
      options,
      async (frame) => {
        if (firstFrameBase64 === undefined) {
          firstFrameBase64 = frame.base64;
        }

        const detection = await detectFoodInFrame(frame.base64);
        if (detection.containsFood) {
          return {
            base64: frame.base64,
            timestamp: frame.timestamp,
            containsFood: true,
            foodDescription: detection.description,
          };
        }
        return null;
      },
    );

    try { fs.unlinkSync(videoPath); } catch {}

    const bestFrames = await selectBestFoodFrames(foodFrames);
    return { foodFrames: bestFrames, firstFrameBase64 };
  } finally {
    cleanupTempDir(tempDir);
  }
}

async function generateRecipe(
  input: { url?: string; imageBase64?: string },
  options?: { userName?: string },
): Promise<GenerateRecipeResult> {
  if (input.imageBase64) {
    const recipe = await generateRecipeFromContent({
      imageBase64: input.imageBase64,
    });
    return {
      recipe,
      sourceAuthorName: options?.userName ?? null,
    };
  }

  if (!input.url) {
    throw new Error("URL or image required");
  }

  const contentInfo = detectContentSource(input.url);

  switch (contentInfo.source) {
    case "youtube": {
      if (!contentInfo.videoId) {
        throw new Error("Invalid YouTube URL");
      }
      const youtubeContent = await parseYouTubeContent(contentInfo.videoId);

      await acquireProcessingSlot();
      try {
        const { foodFrames: bestFrames, firstFrameBase64 } =
          await extractAndFilterFrames(youtubeContent.videoUrl, {
            intervalSeconds: 3,
            maxFrames: 10,
          });
        const recipe = await generateRecipeFromContent({
          transcript: youtubeContent.transcript,
          foodFrames: bestFrames,
          firstFrameBase64,
          sourceTitle: youtubeContent.metadata.title,
          sourceDescription: youtubeContent.metadata.description,
          sourceImageUrls: youtubeContent.metadata.thumbnailUrl
            ? [youtubeContent.metadata.thumbnailUrl]
            : undefined,
        });
        return {
          recipe,
          sourceUrl: input.url,
          sourceTitle: youtubeContent.metadata.title,
          sourceAuthorName: youtubeContent.metadata.channelName || null,
          sourceAuthorAvatarUrl: null,
          savedContentTitle: youtubeContent.metadata.title,
          savedContentThumbnailUrl: youtubeContent.metadata.thumbnailUrl || null,
        };
      } finally {
        releaseProcessingSlot();
      }
    }

    case "tiktok": {
      const tiktokContent = await parseTikTokContent(input.url);
      if (!tiktokContent.videoUrl) {
        throw new Error("Could not extract TikTok video");
      }

      await acquireProcessingSlot();
      try {
        const { foodFrames: bestFrames, firstFrameBase64 } =
          await extractAndFilterFrames(tiktokContent.videoUrl, {
            intervalSeconds: 2,
            maxFrames: 8,
          });
        const recipe = await generateRecipeFromContent({
          transcript: tiktokContent.transcript,
          foodFrames: bestFrames,
          firstFrameBase64,
          sourceTitle: tiktokContent.metadata.title,
          sourceDescription: tiktokContent.metadata.description,
          sourceImageUrls: tiktokContent.metadata.thumbnailUrl
            ? [tiktokContent.metadata.thumbnailUrl]
            : undefined,
        });
        return {
          recipe,
          sourceUrl: input.url,
          sourceTitle: tiktokContent.metadata.title || null,
          sourceAuthorName: tiktokContent.metadata.authorName || null,
          sourceAuthorAvatarUrl: tiktokContent.metadata.authorAvatarUrl || null,
          savedContentTitle: tiktokContent.metadata.title || null,
          savedContentThumbnailUrl: tiktokContent.metadata.thumbnailUrl || null,
        };
      } finally {
        releaseProcessingSlot();
      }
    }

    case "instagram": {
      const instagramContent = await parseInstagramContent(input.url);
      const sourceTitle =
        instagramContent.title || instagramContent.authorName || "Instagram";

      try {
        await acquireProcessingSlot();
        try {
          const { foodFrames: bestFrames, firstFrameBase64 } =
            await extractAndFilterFrames(instagramContent.mediaUrl, {
              intervalSeconds: 2,
              maxFrames: 8,
            });
          const recipe = await generateRecipeFromContent({
            foodFrames: bestFrames,
            firstFrameBase64,
            sourceTitle,
            sourceDescription: instagramContent.caption,
            sourceImageUrls: instagramContent.thumbnailUrl
              ? [instagramContent.thumbnailUrl]
              : undefined,
          });
          return {
            recipe,
            sourceUrl: input.url,
            sourceTitle,
            sourceAuthorName: instagramContent.authorName ?? null,
            sourceAuthorAvatarUrl: null,
            savedContentTitle: sourceTitle,
            savedContentThumbnailUrl: instagramContent.thumbnailUrl ?? null,
          };
        } finally {
          releaseProcessingSlot();
        }
      } catch {
        const recipe = await generateRecipeFromContent({
          sourceTitle,
          sourceDescription: instagramContent.caption,
          sourceImageUrls: instagramContent.thumbnailUrl
            ? [instagramContent.thumbnailUrl, instagramContent.mediaUrl]
            : [instagramContent.mediaUrl],
        });
        return {
          recipe,
          sourceUrl: input.url,
          sourceTitle,
          sourceAuthorName: instagramContent.authorName ?? null,
          sourceAuthorAvatarUrl: null,
          savedContentTitle: sourceTitle,
          savedContentThumbnailUrl: instagramContent.thumbnailUrl ?? null,
        };
      }
    }

    case "facebook": {
      const facebookContent = await parseFacebookContent(input.url);
      const fbSourceTitle =
        facebookContent.title || facebookContent.authorName || "Facebook";

      try {
        await acquireProcessingSlot();
        try {
          const { foodFrames: bestFrames, firstFrameBase64 } =
            await extractAndFilterFrames(facebookContent.mediaUrl, {
              intervalSeconds: 2,
              maxFrames: 8,
            });
          const recipe = await generateRecipeFromContent({
            foodFrames: bestFrames,
            firstFrameBase64,
            sourceTitle: fbSourceTitle,
            sourceDescription: facebookContent.caption,
            sourceImageUrls: facebookContent.thumbnailUrl
              ? [facebookContent.thumbnailUrl]
              : undefined,
          });
          return {
            recipe,
            sourceUrl: input.url,
            sourceTitle: fbSourceTitle,
            sourceAuthorName: facebookContent.authorName ?? null,
            sourceAuthorAvatarUrl: null,
            savedContentTitle: fbSourceTitle,
            savedContentThumbnailUrl: facebookContent.thumbnailUrl ?? null,
          };
        } finally {
          releaseProcessingSlot();
        }
      } catch {
        const recipe = await generateRecipeFromContent({
          sourceTitle: fbSourceTitle,
          sourceDescription: facebookContent.caption,
          sourceImageUrls: facebookContent.thumbnailUrl
            ? [facebookContent.thumbnailUrl, facebookContent.mediaUrl]
            : [facebookContent.mediaUrl],
        });
        return {
          recipe,
          sourceUrl: input.url,
          sourceTitle: fbSourceTitle,
          sourceAuthorName: facebookContent.authorName ?? null,
          sourceAuthorAvatarUrl: null,
          savedContentTitle: fbSourceTitle,
          savedContentThumbnailUrl: facebookContent.thumbnailUrl ?? null,
        };
      }
    }

    case "website": {
      const websiteContent = await parseWebsiteContent(input.url);
      const websiteImageUrls: string[] = [];
      if (websiteContent.recipeSchema?.image?.[0])
        websiteImageUrls.push(websiteContent.recipeSchema.image[0]);
      if (websiteContent.ogImageUrl)
        websiteImageUrls.push(websiteContent.ogImageUrl);
      if (websiteContent.images?.[0])
        websiteImageUrls.push(websiteContent.images[0]);
      const recipe = await generateRecipeFromContent({
        websiteContent: {
          mainContent: websiteContent.mainContent,
          recipeSchema: websiteContent.recipeSchema,
        },
        sourceTitle: websiteContent.title,
        sourceDescription: websiteContent.description,
        sourceImageUrls:
          websiteImageUrls.length > 0 ? websiteImageUrls : undefined,
      });
      const thumb =
        websiteContent.recipeSchema?.image?.[0] ??
        websiteContent.ogImageUrl ??
        websiteContent.images?.[0] ??
        null;
      return {
        recipe,
        sourceUrl: input.url,
        sourceTitle: websiteContent.title || null,
        sourceAuthorName: websiteContent.recipeSchema?.author ?? null,
        sourceAuthorAvatarUrl: null,
        savedContentTitle: websiteContent.title || null,
        savedContentThumbnailUrl: thumb,
      };
    }

    case "image": {
      const imageData = await downloadImageAsBase64(input.url);
      const recipe = await generateRecipeFromContent({
        imageBase64: imageData,
      });
      return {
        recipe,
        sourceUrl: input.url,
      };
    }

    default:
      throw new Error("Unsupported content type");
  }
}

const formatRecipe = (recipe: recipeRepo.Recipe) => ({
  id: recipe.id,
  name: recipe.name,
  description: recipe.description,
  ingredients: recipe.ingredients,
  instructions: JSON.parse(recipe.instructions),
  servings: recipe.servings,
  prepTimeMinutes: recipe.prepTimeMinutes,
  cookTimeMinutes: recipe.cookTimeMinutes,
  imageUrl: recipe.imageUrl,
  sourceUrl: recipe.sourceUrl ?? undefined,
  sourceTitle: recipe.sourceTitle ?? undefined,
  sourceAuthorName: recipe.sourceAuthorName ?? undefined,
  sourceAuthorAvatarUrl: recipe.sourceAuthorAvatarUrl ?? undefined,
});

const getJobs = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const statusParam = req.query.status as string | undefined;
    const statuses = statusParam ? statusParam.split(",") : undefined;

    const results = await contentRepo.findJobsWithRecipes(userId, statuses);

    const jobs = results.map(({ job, recipe, savedContent }) => ({
      id: job.id,
      savedContentId: job.savedContentId,
      status: job.status,
      progress: job.progress,
      error: job.error,
      createdAt: job.createdAt,
      recipe: recipe ? formatRecipe(recipe) : undefined,
      savedContent: savedContent
        ? {
            sourceUrl: savedContent.sourceUrl,
            title: savedContent.title ?? undefined,
            thumbnailUrl: savedContent.thumbnailUrl ?? undefined,
          }
        : undefined,
    }));

    return res.status(200).json({ jobs });
  } catch (error) {
    logger.error("Error fetching jobs:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to fetch jobs",
    });
  }
};

const getJobById = async (req: Request, res: Response) => {
  try {
    const jobId = req.params.jobId as string;
    const result = await contentRepo.findJobWithRecipe(jobId);

    if (!result) {
      return res.status(404).json({ error: "Job not found" });
    }

    if (result.job.userId !== req.user.id) {
      return res.status(403).json({ error: "Forbidden" });
    }

    return res.status(200).json({
      id: result.job.id,
      savedContentId: result.job.savedContentId,
      status: result.job.status,
      progress: result.job.progress,
      error: result.job.error,
      createdAt: result.job.createdAt,
      recipe: result.recipe ? formatRecipe(result.recipe) : undefined,
      savedContent: result.savedContent
        ? {
            sourceUrl: result.savedContent.sourceUrl,
            title: result.savedContent.title ?? undefined,
            thumbnailUrl: result.savedContent.thumbnailUrl ?? undefined,
          }
        : undefined,
    });
  } catch (error) {
    logger.error("Error fetching job:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to fetch job",
    });
  }
};

export default { parseContent, getJobs, getJobById };
