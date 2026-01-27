import OpenAI from "openai";
import { env } from "../../../../env_config";
import { logger } from "../../../../logger";
import { RecipeSchema } from "./website.service";
import { FrameWithFood } from "./food-detection.service";

const openai = new OpenAI({
  apiKey: env.OPENAI_API_KEY,
});

interface GeneratedRecipe {
  name: string;
  description: string;
  ingredients: Ingredient[];
  instructions: string[];
  servings?: number;
  prepTimeMinutes?: number;
  cookTimeMinutes?: number;
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

async function generateRecipeFromContent(
  input: RecipeGenerationInput
): Promise<GeneratedRecipe> {
  const messages: OpenAI.ChatCompletionMessageParam[] = [
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

  const userContent: OpenAI.ChatCompletionContentPart[] = [];

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
        type: "image_url",
        image_url: {
          url: frame.base64,
          detail: "low",
        },
      });
    }
  }

  if (input.imageBase64) {
    userContent.push({
      type: "image_url",
      image_url: {
        url: input.imageBase64,
        detail: "high",
      },
    });
  }

  messages.push({ role: "user", content: userContent });

  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o",
      messages,
      max_tokens: 2000,
      response_format: { type: "json_object" },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      throw new Error("No response from OpenAI");
    }

    const recipe = JSON.parse(content) as GeneratedRecipe;

    return {
      name: recipe.name || "Untitled Recipe",
      description: recipe.description || "",
      ingredients: recipe.ingredients || [],
      instructions: recipe.instructions || [],
      servings: recipe.servings,
      prepTimeMinutes: recipe.prepTimeMinutes,
      cookTimeMinutes: recipe.cookTimeMinutes,
    };
  } catch (error) {
    logger.error("Error generating recipe:", error);
    throw new Error("Failed to generate recipe from content");
  }
}

async function generateRecipeFromImage(
  imageBase64: string
): Promise<GeneratedRecipe> {
  return generateRecipeFromContent({ imageBase64 });
}

async function generateRecipeFromTranscript(
  transcript: string,
  foodFrames?: FrameWithFood[]
): Promise<GeneratedRecipe> {
  return generateRecipeFromContent({ transcript, foodFrames });
}

async function generateRecipeFromWebsite(
  mainContent: string,
  recipeSchema?: RecipeSchema
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
