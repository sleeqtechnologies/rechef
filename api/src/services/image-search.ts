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

const imageSelectionSchema = z.object({
  imageUrl: z.string().url().nullable().optional(),
});

async function searchFoodImages(query: string, limit = 6): Promise<string[]> {
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
    return data.results.map((result) => result.urls.regular).filter(Boolean);
  } catch (error) {
    logger.error("Unsplash search error", error);
    return [];
  }
}

async function selectBestImageUrl(input: {
  recipeName: string;
  description?: string;
  candidateUrls: string[];
}): Promise<string | undefined> {
  const { recipeName, description, candidateUrls } = input;

  if (!candidateUrls.length) {
    return undefined;
  }

  if (candidateUrls.length === 1) {
    return candidateUrls[0];
  }

  try {
    const { object } = await generateObject({
      model: openai("gpt-5.2"),
      schema: imageSelectionSchema,
      messages: [
        {
          role: "system",
          content:
            "Select the single best image URL that matches the recipe. " +
            "Only choose from the provided list.",
        },
        {
          role: "user",
          content: [
            {
              type: "text",
              text:
                `Recipe Name: ${recipeName}\n` +
                `Description: ${description || ""}\n\n` +
                "Candidate URLs:\n" +
                candidateUrls
                  .map((url, index) => `${index + 1}. ${url}`)
                  .join("\n"),
            },
          ],
        },
      ],
    });

    if (object.imageUrl && candidateUrls.includes(object.imageUrl)) {
      return object.imageUrl;
    }

    return candidateUrls[0];
  } catch (error) {
    logger.error("Failed to select image URL", error);
    return candidateUrls[0];
  }
}

export { searchFoodImages, selectBestImageUrl };
