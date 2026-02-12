import { z } from "zod";
import { generateObject } from "ai";
import { openai } from "@ai-sdk/openai";
import { env } from "../../env_config";
import { logger } from "../../logger";

type UnsplashSearchResponse = {
  results: Array<{
    id: string;
    alt_description: string | null;
    description: string | null;
    urls: {
      raw: string;
      full: string;
      regular: string;
      small: string;
      thumb: string;
    };
  }>;
};

type ImageCandidate = {
  url: string;
  description: string;
};

const imageSelectionSchema = z.object({
  selectedIndex: z
    .number()
    .int()
    .min(0)
    .describe("Zero-based index of the best matching image"),
});

type UnsplashImageSize = "raw" | "full" | "regular" | "small" | "thumb";

async function searchFoodImages(
  query: string,
  limit?: number,
  size?: UnsplashImageSize,
): Promise<string[]>;
async function searchFoodImages(
  query: string,
  limit: number,
  size: UnsplashImageSize,
  withMetadata: true,
): Promise<ImageCandidate[]>;
async function searchFoodImages(
  query: string,
  limit = 6,
  size: UnsplashImageSize = "regular",
  withMetadata = false,
): Promise<string[] | ImageCandidate[]> {
  if (!env.UNSPLASH_ACCESS_KEY) {
    logger.warn("UNSPLASH_ACCESS_KEY is missing");
    return [];
  }

  const url =
    "https://api.unsplash.com/search/photos" +
    `?query=${encodeURIComponent(query)}` +
    `&per_page=${Math.min(Math.max(limit, 1), 10)}` +
    "&content_filter=high" +
    "&orientation=landscape";

  try {
    const response = await fetch(url, {
      headers: {
        Authorization: `Client-ID ${env.UNSPLASH_ACCESS_KEY}`,
        "Accept-Version": "v1",
      },
    });

    if (!response.ok) {
      logger.error("Unsplash search failed", {
        status: response.status,
        statusText: response.statusText,
      });
      return [];
    }

    const data = (await response.json()) as UnsplashSearchResponse;

    if (withMetadata) {
      return data.results
        .filter((r) => r.urls[size])
        .map((r) => ({
          url: r.urls[size],
          description:
            r.alt_description || r.description || "No description available",
        }));
    }

    return data.results.map((result) => result.urls[size]).filter(Boolean);
  } catch (error) {
    logger.error("Unsplash search error", error);
    return [];
  }
}

async function selectBestImageUrl(input: {
  recipeName: string;
  description?: string;
  candidates: ImageCandidate[];
}): Promise<string | undefined> {
  const { recipeName, description, candidates } = input;

  if (!candidates.length) {
    return undefined;
  }

  if (candidates.length === 1) {
    return candidates[0].url;
  }

  try {
    const candidateList = candidates
      .map(
        (c, i) => `${i}. "${c.description}"`,
      )
      .join("\n");

    const { object } = await generateObject({
      model: openai("gpt-4o-mini"),
      schema: imageSelectionSchema,
      messages: [
        {
          role: "system",
          content:
            "You are selecting the best stock photo for a recipe. " +
            "You will be given a recipe name, its description, and a numbered list of image descriptions from Unsplash. " +
            "Pick the image whose description best matches the finished dish. " +
            "Prefer images that show the actual prepared dish over raw ingredients or unrelated food. " +
            "Return the zero-based index of your selection.",
        },
        {
          role: "user",
          content:
            `Recipe: ${recipeName}\n` +
            `Description: ${description || "N/A"}\n\n` +
            `Image candidates:\n${candidateList}`,
        },
      ],
    });

    const idx = object.selectedIndex;
    if (idx >= 0 && idx < candidates.length) {
      return candidates[idx].url;
    }

    return candidates[0].url;
  } catch (error) {
    logger.error("Failed to select image URL", error);
    return candidates[0].url;
  }
}

export { searchFoodImages, selectBestImageUrl, type ImageCandidate };
