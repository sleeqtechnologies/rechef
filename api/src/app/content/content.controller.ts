import { logger } from "../../../logger";
import { Request, Response } from "express";
import { ParseContentSchema } from "./content.validation";
import { detectContentSource } from "../../services/content-detector";
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

export default { parseContent };
