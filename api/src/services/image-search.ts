import { z } from "zod";
import { generateObject } from "ai";
import { openai } from "@ai-sdk/openai";
import { env } from "../../env_config";
import { logger } from "../../logger";

type UnsplashPhoto = {
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
};

type UnsplashSearchResponse = {
  results: UnsplashPhoto[];
};

type ImageCandidate = {
  regularUrl: string;
  smallUrl: string;
  description: string;
};

type ImageCandidate = {
  url: string;
  description: string;
};

const imageSelectionSchema = z.object({
  selectedIndex: z
    .number()
    .int()
    .describe("The 1-indexed number of the best matching image"),
});

async function searchFoodImages(
  query: string,
  limit = 6,
): Promise<ImageCandidate[]> {
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
    return data.results
      .filter((result) => result.urls.regular)
      .map((result) => ({
        regularUrl: result.urls.regular,
        smallUrl: result.urls.small,
        description: result.alt_description || result.description || "",
      }));
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
    return candidates[0].regularUrl;
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
            "You are selecting the best photo for a recipe. " +
            "Pick the image that best matches the dish AND follows these rules:\n" +
            "- MUST show ONLY the food — no people, hands, or faces\n" +
            "- Should be a clean, professional-looking photo\n" +
            "- Food should be plated/presented and fill most of the frame\n" +
            "- Prefer well-lit, appetizing, high-quality shots\n" +
            "- Avoid busy backgrounds or cluttered scenes\n" +
            "Respond with the number of the best image (1-indexed).",
        },
        {
          role: "user",
          content: [
            {
              type: "text",
              text:
                `Recipe: ${recipeName}\n` +
                `Description: ${description || "N/A"}\n\n` +
                "Pick the best image from the following candidates:",
            },
            ...candidates.map((candidate, index) => [
              {
                type: "text" as const,
                text: `\nImage ${index + 1}${candidate.description ? ` — ${candidate.description}` : ""}:`,
              },
              {
                type: "image" as const,
                image: candidate.smallUrl,
              },
            ]).flat(),
          ],
        },
      ],
    });

    const selectedIndex = object.selectedIndex;
    if (
      selectedIndex != null &&
      selectedIndex >= 1 &&
      selectedIndex <= candidates.length
    ) {
      return candidates[selectedIndex - 1].regularUrl;
    }

    return candidates[0].regularUrl;
  } catch (error) {
    logger.error("Failed to select image URL", error);
    return candidates[0].regularUrl;
  }
}

export { searchFoodImages, selectBestImageUrl, type ImageCandidate };
