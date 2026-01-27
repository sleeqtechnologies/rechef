import { logger } from "../../../logger";
import { Request, Response } from "express";
import { ParseContentSchema, GetJobStatusSchema } from "./content.validation";
import { detectContentSource } from "./services/content-detector.service";
import { parseYouTubeContent, isLongVideo } from "./services/youtube.service";
import {
  parseTikTokContent,
  isLongTikTokVideo,
} from "./services/tiktok.service";
import { parseWebsiteContent } from "./services/website.service";
import {
  extractFramesFromUrl,
  downloadImageAsBase64,
} from "./services/frame-extractor.service";
import {
  filterFoodFrames,
  selectBestFoodFrames,
} from "./services/food-detection.service";
import { generateRecipeFromContent } from "./services/recipe-generator.service";
import {
  startAsyncJob,
  getJobStatus,
  shouldProcessAsync,
} from "./services/job.service";

const parseContent = async (
  req: Request<{}, {}, ParseContentSchema>,
  res: Response,
) => {
  try {
    const { url, imageBase64 } = req.body;

    if (imageBase64) {
      const recipe = await generateRecipeFromContent({ imageBase64 });
      return res.status(200).json({ recipe });
    }

    if (!url) {
      return res.status(400).json({ error: "URL or image required" });
    }

    const isAsync = await shouldProcessAsync(url);

    if (isAsync) {
      const jobId = startAsyncJob(url);
      return res.status(202).json({
        jobId,
        status: "processing",
        message: "Content is being processed. Check job status for updates.",
      });
    }

    const contentInfo = detectContentSource(url);

    switch (contentInfo.source) {
      case "youtube": {
        if (!contentInfo.videoId) {
          return res.status(400).json({ error: "Invalid YouTube URL" });
        }

        const youtubeContent = await parseYouTubeContent(contentInfo.videoId);
        const frames = await extractFramesFromUrl(youtubeContent.videoUrl, {
          intervalSeconds: 3,
          maxFrames: 10,
        });
        const foodFrames = await filterFoodFrames(frames);
        const bestFrames = await selectBestFoodFrames(foodFrames);

        const recipe = await generateRecipeFromContent({
          transcript: youtubeContent.transcript,
          foodFrames: bestFrames,
          sourceTitle: youtubeContent.metadata.title,
          sourceDescription: youtubeContent.metadata.description,
        });

        return res.status(200).json({ recipe });
      }

      case "tiktok": {
        const tiktokContent = await parseTikTokContent(url);

        if (!tiktokContent.videoUrl) {
          return res
            .status(400)
            .json({ error: "Could not extract TikTok video" });
        }

        const frames = await extractFramesFromUrl(tiktokContent.videoUrl, {
          intervalSeconds: 2,
          maxFrames: 8,
        });
        const foodFrames = await filterFoodFrames(frames);
        const bestFrames = await selectBestFoodFrames(foodFrames);

        const recipe = await generateRecipeFromContent({
          transcript: tiktokContent.transcript,
          foodFrames: bestFrames,
          sourceTitle: tiktokContent.metadata.title,
          sourceDescription: tiktokContent.metadata.description,
        });

        return res.status(200).json({ recipe });
      }

      case "website": {
        const websiteContent = await parseWebsiteContent(url);

        const recipe = await generateRecipeFromContent({
          websiteContent: {
            mainContent: websiteContent.mainContent,
            recipeSchema: websiteContent.recipeSchema,
          },
          sourceTitle: websiteContent.title,
          sourceDescription: websiteContent.description,
        });

        return res.status(200).json({ recipe });
      }

      case "image": {
        const imageData = await downloadImageAsBase64(url);
        const recipe = await generateRecipeFromContent({
          imageBase64: imageData,
        });
        return res.status(200).json({ recipe });
      }

      default:
        return res.status(400).json({ error: "Unsupported content type" });
    }
  } catch (error) {
    logger.error("Error parsing content:", error);
    return res.status(500).json({
      error: error instanceof Error ? error.message : "Failed to parse content",
    });
  }
};

const checkJobStatus = async (
  req: Request<GetJobStatusSchema>,
  res: Response,
) => {
  try {
    const { jobId } = req.params;

    const status = getJobStatus(jobId);

    if (!status) {
      return res.status(404).json({ error: "Job not found" });
    }

    return res.status(200).json(status);
  } catch (error) {
    logger.error("Error checking job status:", error);
    return res.status(500).json({ error: "Failed to check job status" });
  }
};

export default { parseContent, checkJobStatus };
