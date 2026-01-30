import { generateObject, type ModelMessage, type UserContent } from "ai";
import { openai } from "@ai-sdk/openai";
import { z } from "zod";
import { logger } from "../../logger";
import { RecipeSchema } from "./website";
import { FrameWithFood } from "./food-detection";
import { searchFoodImages, selectBestImageUrl } from "./image-search";

interface GeneratedRecipe {
  name: string;
  description: string;
  ingredients: Ingredient[];
  instructions: string[];
  servings?: number;
  prepTimeMinutes?: number;
  cookTimeMinutes?: number;
  imageUrl?: string;
}

interface Ingredient {
  name: string;
  quantity: string;
  unit?: string;
  notes?: string;
}

interface RecipeGenerationInput {
  transcript?: string;
  foodFrames?: FrameWithFood[];
  websiteContent?: {
    mainContent: string;
    recipeSchema?: RecipeSchema;
  };
  imageBase64?: string;
  sourceTitle?: string;
  sourceDescription?: string;
}

const ingredientSchema = z.object({
  name: z.string().default(""),
  quantity: z.string().default(""),
  unit: z.string().optional(),
  notes: z.string().optional(),
});

const generatedRecipeSchema = z.object({
  name: z.string().default("Untitled Recipe"),
  description: z.string().default(""),
  ingredients: z.array(ingredientSchema).default([]),
  instructions: z.array(z.string()).default([]),
  servings: z.number().nullable().optional(),
  prepTimeMinutes: z.number().nullable().optional(),
  cookTimeMinutes: z.number().nullable().optional(),
  imageUrl: z.string().url().optional(),
});

async function generateRecipeFromContent(
  input: RecipeGenerationInput,
): Promise<GeneratedRecipe> {
  const messages: ModelMessage[] = [
    {
      role: "system",
      content: `You are a professional chef and recipe writer. Your task is to analyze the provided content (which may include video transcripts, images of food, or website content) and generate a complete, accurate recipe.

Generate a recipe in the following JSON format:
{
  "name": "Recipe Name",
  "description": "A brief appetizing description of the dish",
  "ingredients": [
    {
      "name": "ingredient name",
      "quantity": "amount",
      "unit": "measurement unit (optional)",
      "notes": "any special notes like 'diced' or 'room temperature' (optional)"
    }
  ],
  "instructions": ["Step 1 instruction", "Step 2 instruction", "Step 3 instruction"],
  "servings": number or null,
  "prepTimeMinutes": number or null,
  "cookTimeMinutes": number or null
}

Guidelines:
- Extract accurate ingredient quantities when mentioned
- Infer reasonable quantities when not explicitly stated
- Provide clear, numbered step-by-step instructions
- Include helpful tips mentioned in the source content
- If the source is unclear about certain details, make reasonable assumptions based on standard cooking practices`,
    },
  ];

  const userContent: UserContent = [];

  let textPrompt = "Generate a recipe based on the following content:\n\n";

  if (input.sourceTitle) {
    textPrompt += `Source Title: ${input.sourceTitle}\n`;
  }

  if (input.sourceDescription) {
    textPrompt += `Description: ${input.sourceDescription}\n\n`;
  }

  if (input.transcript) {
    textPrompt += `Video Transcript:\n${input.transcript}\n\n`;
  }

  if (input.websiteContent?.recipeSchema) {
    const schema = input.websiteContent.recipeSchema;
    textPrompt += `Existing Recipe Data:\n`;
    textPrompt += `Name: ${schema.name}\n`;
    textPrompt += `Ingredients: ${schema.ingredients.join(", ")}\n`;
    textPrompt += `Instructions: ${schema.instructions.join(" ")}\n\n`;
  } else if (input.websiteContent?.mainContent) {
    textPrompt += `Website Content:\n${input.websiteContent.mainContent.slice(0, 5000)}\n\n`;
  }

  userContent.push({ type: "text", text: textPrompt });

  if (input.foodFrames && input.foodFrames.length > 0) {
    const framesToInclude = input.foodFrames.slice(0, 5);
    for (const frame of framesToInclude) {
      userContent.push({
        type: "image",
        image: frame.base64,
      });
    }
  }

  if (input.imageBase64) {
    userContent.push({
      type: "image",
      image: input.imageBase64,
    });
  }

  messages.push({ role: "user", content: userContent });

  try {
    const { object } = await generateObject({
      model: openai("gpt-5.2"),
      schema: generatedRecipeSchema,
      messages,
    });

    const name = object.name || "Untitled Recipe";
    const description = object.description || "";
    const ingredients = object.ingredients || [];

    const ingredientTerms = ingredients
      .map((ingredient) => ingredient.name)
      .filter(Boolean)
      .slice(0, 3)
      .join(" ");

    const searchQuery = [name, ingredientTerms].filter(Boolean).join(" ");
    const candidateUrls = await searchFoodImages(`${searchQuery} food`);
    const imageUrl = await selectBestImageUrl({
      recipeName: name,
      description,
      candidateUrls,
    });

    return {
      name,
      description,
      ingredients,
      instructions: object.instructions || [],
      servings: object.servings ?? undefined,
      prepTimeMinutes: object.prepTimeMinutes ?? undefined,
      cookTimeMinutes: object.cookTimeMinutes ?? undefined,
      imageUrl,
    };
  } catch (error) {
    logger.error("Error generating recipe:", error);
    throw new Error("Failed to generate recipe from content");
  }
}

async function generateRecipeFromImage(
  imageBase64: string,
): Promise<GeneratedRecipe> {
  return generateRecipeFromContent({ imageBase64 });
}

async function generateRecipeFromTranscript(
  transcript: string,
  foodFrames?: FrameWithFood[],
): Promise<GeneratedRecipe> {
  return generateRecipeFromContent({ transcript, foodFrames });
}

async function generateRecipeFromWebsite(
  mainContent: string,
  recipeSchema?: RecipeSchema,
): Promise<GeneratedRecipe> {
  return generateRecipeFromContent({
    websiteContent: { mainContent, recipeSchema },
  });
}

export {
  generateRecipeFromContent,
  generateRecipeFromImage,
  generateRecipeFromTranscript,
  generateRecipeFromWebsite,
  GeneratedRecipe,
  Ingredient,
  RecipeGenerationInput,
};
