import { generateObject, type ModelMessage } from "ai";
import { openai } from "@ai-sdk/openai";
import { z } from "zod";
import { logger } from "../../logger";

interface NutritionGenerationIngredient {
  name: string;
  quantity?: string;
  unit?: string;
}

interface NutritionGenerationInput {
  name: string;
  description?: string;
  servings?: number | null;
  ingredients: NutritionGenerationIngredient[];
}

interface GeneratedNutrition {
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
}

const nutritionFactsSchema = z.object({
  calories: z.number().nonnegative().default(0),
  protein_g: z.number().nonnegative().default(0),
  carbs_g: z.number().nonnegative().default(0),
  fat_g: z.number().nonnegative().default(0),
});

async function generateNutritionForRecipe(
  input: NutritionGenerationInput,
): Promise<GeneratedNutrition> {
  const messages: ModelMessage[] = [
    {
      role: "system",
      content: `You are a certified nutritionist. Given a recipe, estimate realistic per-serving nutrition facts.

Return ONLY a JSON object with this exact shape:
{
  "calories": number,      // kcal per serving
  "protein_g": number,     // grams of protein per serving
  "carbs_g": number,       // grams of carbohydrates per serving
  "fat_g": number          // grams of fat per serving
}

Guidelines:
- Use standard nutrition databases as a mental reference.
- Base your estimate on the ingredient list and servings.
- If servings is missing, assume 2–4 servings depending on the amount of food.
- Do NOT include any other fields or commentary.`,
    },
    {
      role: "user",
      content: [
        {
          type: "text",
          text: buildNutritionPrompt(input),
        },
      ],
    },
  ];

  try {
    const { object } = await generateObject({
      model: openai("gpt-5.2"),
      schema: nutritionFactsSchema,
      messages,
    });

    return {
      calories: object.calories ?? 0,
      protein_g: object.protein_g ?? 0,
      carbs_g: object.carbs_g ?? 0,
      fat_g: object.fat_g ?? 0,
    };
  } catch (error) {
    logger.error("Error generating nutrition facts:", error);
    throw new Error("Failed to generate nutrition facts");
  }
}

function buildNutritionPrompt(input: NutritionGenerationInput): string {
  const lines: string[] = [];
  lines.push(`Recipe name: ${input.name}`);

  if (input.description) {
    lines.push(`Description: ${input.description}`);
  }

  if (input.servings != null) {
    lines.push(`Servings: ${input.servings}`);
  }

  lines.push("");
  lines.push("Ingredients:");
  for (const ingredient of input.ingredients) {
    const parts = [ingredient.name];
    if (ingredient.quantity) parts.push(ingredient.quantity);
    if (ingredient.unit) parts.push(ingredient.unit);
    lines.push(`- ${parts.join(" ")}`);
  }

  return lines.join("\n");
}

export {
  generateNutritionForRecipe,
  GeneratedNutrition,
  NutritionGenerationInput,
  NutritionGenerationIngredient,
};

