import { logger } from "../../../logger";
import { Request, Response } from "express";
import { ParseContentSchema } from "./content.validation";
import { detectContentSource, ContentSource } from "../../services/content-detector";
import { parseYouTubeContent } from "../../services/youtube";
import { parseTikTokContent } from "../../services/tiktok";
import { parseWebsiteContent } from "../../services/website";
import {
  extractFramesFromUrl,
  downloadImageAsBase64,
} from "../../services/frame-extractor";
import {
  filterFoodFrames,
  selectBestFoodFrames,
} from "../../services/food-detection";
import { generateRecipeFromContent } from "../../services/recipe-generator";
import * as contentRepo from "./content.repository";
import * as recipeRepo from "../recipe/recipe.repository";

function contentSourceToType(source: ContentSource): "video" | "image" | "website" {
  switch (source) {
    case "youtube":
    case "tiktok":
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
    const contentType = url ? contentSourceToType(detectContentSource(url).source) : "image";

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

    processContentInBackground(job.id, savedContent.id, userId, { url, imageBase64 });
  } catch (error) {
    logger.error("Error initiating content parse:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to initiate content parsing",
    });
  }
};

async function processContentInBackground(
  jobId: string,
  savedContentId: string,
  userId: string,
  input: { url?: string; imageBase64?: string },
) {
  try {
    await contentRepo.updateJobStatus(jobId, "processing", { progress: 10 });

    const recipe = await generateRecipe(input);

    await contentRepo.updateJobStatus(jobId, "completed", { progress: 100 });
    await contentRepo.updateSavedContentStatus(savedContentId, "processed");

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

async function generateRecipe(input: { url?: string; imageBase64?: string }) {
  if (input.imageBase64) {
    return generateRecipeFromContent({ imageBase64: input.imageBase64 });
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
      const frames = await extractFramesFromUrl(youtubeContent.videoUrl, {
        intervalSeconds: 3,
        maxFrames: 10,
      });
      const foodFrames = await filterFoodFrames(frames);
      const bestFrames = await selectBestFoodFrames(foodFrames);
      return generateRecipeFromContent({
        transcript: youtubeContent.transcript,
        foodFrames: bestFrames,
        sourceTitle: youtubeContent.metadata.title,
        sourceDescription: youtubeContent.metadata.description,
      });
    }

    case "tiktok": {
      const tiktokContent = await parseTikTokContent(input.url);
      if (!tiktokContent.videoUrl) {
        throw new Error("Could not extract TikTok video");
      }
      const frames = await extractFramesFromUrl(tiktokContent.videoUrl, {
        intervalSeconds: 2,
        maxFrames: 8,
      });
      const foodFrames = await filterFoodFrames(frames);
      const bestFrames = await selectBestFoodFrames(foodFrames);
      return generateRecipeFromContent({
        transcript: tiktokContent.transcript,
        foodFrames: bestFrames,
        sourceTitle: tiktokContent.metadata.title,
        sourceDescription: tiktokContent.metadata.description,
      });
    }

    case "website": {
      const websiteContent = await parseWebsiteContent(input.url);
      return generateRecipeFromContent({
        websiteContent: {
          mainContent: websiteContent.mainContent,
          recipeSchema: websiteContent.recipeSchema,
        },
        sourceTitle: websiteContent.title,
        sourceDescription: websiteContent.description,
      });
    }

    case "image": {
      const imageData = await downloadImageAsBase64(input.url);
      return generateRecipeFromContent({ imageBase64: imageData });
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
});

const getJobs = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const statusParam = req.query.status as string | undefined;
    const statuses = statusParam ? statusParam.split(",") : undefined;

    const results = await contentRepo.findJobsWithRecipes(userId, statuses);

    const jobs = results.map(({ job, recipe }) => ({
      id: job.id,
      savedContentId: job.savedContentId,
      status: job.status,
      progress: job.progress,
      error: job.error,
      createdAt: job.createdAt,
      recipe: recipe ? formatRecipe(recipe) : undefined,
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
    });
  } catch (error) {
    logger.error("Error fetching job:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to fetch job",
    });
  }
};

export default { parseContent, getJobs, getJobById };
