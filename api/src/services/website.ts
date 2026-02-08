import * as cheerio from "cheerio";
import { logger } from "../../logger";

interface RecipeSchema {
  name: string;
  description: string;
  image: string[];
  ingredients: string[];
  instructions: string[];
  prepTime?: string;
  cookTime?: string;
  totalTime?: string;
  servings?: string;
  author?: string;
}

interface WebsiteContent {
  title: string;
  description: string;
  mainContent: string;
  images: string[];
  ogImageUrl?: string;
  recipeSchema?: RecipeSchema;
  url: string;
}

async function fetchWebsitePage(url: string): Promise<string> {
  const response = await fetch(url, {
    headers: {
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      Accept:
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
      "Accept-Language": "en-US,en;q=0.5",
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch website: ${response.status}`);
  }

  return response.text();
}

function extractRecipeSchema(html: string): RecipeSchema | undefined {
  const $ = cheerio.load(html);

  const scriptTags = $('script[type="application/ld+json"]');

  let recipeData: RecipeSchema | undefined;

  scriptTags.each((_, element) => {
    try {
      const jsonContent = $(element).html();
      if (!jsonContent) return;

      const data = JSON.parse(jsonContent);
      const recipe = findRecipeInJsonLd(data);

      if (recipe) {
        recipeData = parseRecipeSchema(recipe);
        return false;
      }
    } catch {
      // Continue to next script tag
    }
  });

  return recipeData;
}

function findRecipeInJsonLd(data: unknown): unknown {
  if (!data || typeof data !== "object") return null;

  if (Array.isArray(data)) {
    for (const item of data) {
      const recipe = findRecipeInJsonLd(item);
      if (recipe) return recipe;
    }
    return null;
  }

  const obj = data as Record<string, unknown>;

  if (obj["@type"] === "Recipe") {
    return obj;
  }

  if (obj["@graph"] && Array.isArray(obj["@graph"])) {
    for (const item of obj["@graph"]) {
      const recipe = findRecipeInJsonLd(item);
      if (recipe) return recipe;
    }
  }

  return null;
}

function parseRecipeSchema(data: unknown): RecipeSchema {
  const recipe = data as Record<string, unknown>;

  return {
    name: String(recipe.name || ""),
    description: String(recipe.description || ""),
    image: normalizeImages(recipe.image),
    ingredients: normalizeStringArray(recipe.recipeIngredient),
    instructions: normalizeInstructions(recipe.recipeInstructions),
    prepTime: recipe.prepTime ? String(recipe.prepTime) : undefined,
    cookTime: recipe.cookTime ? String(recipe.cookTime) : undefined,
    totalTime: recipe.totalTime ? String(recipe.totalTime) : undefined,
    servings: recipe.recipeYield ? String(recipe.recipeYield) : undefined,
    author: extractAuthor(recipe.author),
  };
}

function normalizeImages(images: unknown): string[] {
  if (!images) return [];
  if (typeof images === "string") return [images];
  if (Array.isArray(images)) {
    return images
      .map((img) => {
        if (typeof img === "string") return img;
        if (img && typeof img === "object" && "url" in img)
          return String(img.url);
        return "";
      })
      .filter(Boolean);
  }
  if (typeof images === "object" && images !== null && "url" in images) {
    return [String((images as Record<string, unknown>).url)];
  }
  return [];
}

function normalizeStringArray(arr: unknown): string[] {
  if (!arr) return [];
  if (typeof arr === "string") return [arr];
  if (Array.isArray(arr)) {
    return arr.map((item) => String(item)).filter(Boolean);
  }
  return [];
}

function normalizeInstructions(instructions: unknown): string[] {
  if (!instructions) return [];
  if (typeof instructions === "string") return [instructions];

  if (Array.isArray(instructions)) {
    return instructions
      .flatMap((instruction) => {
        if (typeof instruction === "string") return instruction;

        if (instruction && typeof instruction === "object") {
          const obj = instruction as Record<string, unknown>;

          if (obj["@type"] === "HowToStep" && obj.text) {
            return String(obj.text);
          }

          if (
            obj["@type"] === "HowToSection" &&
            Array.isArray(obj.itemListElement)
          ) {
            return normalizeInstructions(obj.itemListElement);
          }
        }

        return [];
      })
      .filter(Boolean);
  }

  return [];
}

function extractAuthor(author: unknown): string | undefined {
  if (!author) return undefined;
  if (typeof author === "string") return author;
  if (Array.isArray(author) && author.length > 0) {
    return extractAuthor(author[0]);
  }
  if (typeof author === "object" && author !== null) {
    const obj = author as Record<string, unknown>;
    return obj.name ? String(obj.name) : undefined;
  }
  return undefined;
}

function extractMainContent(html: string): string {
  const $ = cheerio.load(html);

  $("script, style, nav, header, footer, aside, .ads, .advertisement").remove();

  const selectors = [
    "article",
    '[class*="recipe"]',
    '[class*="content"]',
    "main",
    ".post-content",
    ".entry-content",
  ];

  for (const selector of selectors) {
    const element = $(selector).first();
    if (element.length) {
      return cleanText(element.text());
    }
  }

  return cleanText($("body").text());
}

function extractImages(html: string, baseUrl: string): string[] {
  const $ = cheerio.load(html);
  const images: string[] = [];

  $("img").each((_, element) => {
    const src =
      $(element).attr("src") ||
      $(element).attr("data-src") ||
      $(element).attr("data-lazy-src");

    if (src) {
      try {
        const absoluteUrl = new URL(src, baseUrl).href;
        images.push(absoluteUrl);
      } catch {
        // Invalid URL, skip
      }
    }
  });

  return images.slice(0, 10);
}

function cleanText(text: string): string {
  return text.replace(/\s+/g, " ").replace(/\n+/g, "\n").trim().slice(0, 10000);
}

async function parseWebsiteContent(url: string): Promise<WebsiteContent> {
  try {
    const html = await fetchWebsitePage(url);
    const $ = cheerio.load(html);

    const title =
      $('meta[property="og:title"]').attr("content") || $("title").text() || "";

    const description =
      $('meta[property="og:description"]').attr("content") ||
      $('meta[name="description"]').attr("content") ||
      "";

    const ogImageRaw = $('meta[property="og:image"]').attr("content");
    let ogImageUrl: string | undefined;
    if (ogImageRaw) {
      try {
        ogImageUrl = new URL(ogImageRaw, url).href;
      } catch {
        ogImageUrl = ogImageRaw;
      }
    }

    const recipeSchema = extractRecipeSchema(html);
    const mainContent = extractMainContent(html);
    const images = extractImages(html, url);

    return {
      title: cleanText(title),
      description: cleanText(description),
      mainContent,
      images,
      ogImageUrl,
      recipeSchema,
      url,
    };
  } catch (error) {
    logger.error("Failed to parse website content:", error);
    throw new Error("Failed to parse website content");
  }
}

export {
  parseWebsiteContent,
  extractRecipeSchema,
  extractMainContent,
  WebsiteContent,
  RecipeSchema,
};
