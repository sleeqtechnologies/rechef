import { generateObject } from "ai";
import { openai } from "@ai-sdk/openai";
import { z } from "zod";
import { logger } from "../../logger";

const matchSchema = z.object({
  matches: z.array(
    z.object({
      ingredientIndex: z.number(),
      matched: z.boolean(),
    }),
  ),
});

/**
 * Uses AI to fuzzy-match recipe ingredient names against pantry item names.
 * Returns a Set of ingredient indices that have a match in the pantry.
 *
 * Example: ingredient "Diced white onion" matches pantry item "onion".
 */
async function matchIngredientsWithPantry(
  ingredientNames: string[],
  pantryItemNames: string[],
): Promise<Set<number>> {
  const matched = new Set<number>();
  if (ingredientNames.length === 0 || pantryItemNames.length === 0) {
    return matched;
  }

  try {
    const { object } = await generateObject({
      model: openai("gpt-4o-mini"),
      schema: matchSchema,
      messages: [
        {
          role: "system",
          content: `You are a kitchen assistant. The user has a pantry with specific items. For each recipe ingredient, determine if the user likely has it in their pantry.

Match generously:
- "Diced white onion" should match pantry item "onion"
- "Garlic cloves" should match "garlic"
- "Tomato purée / tomato paste" should match "tomato paste"
- "Light cream cheese" should match "cream cheese"
- "Chicken stock" should match "chicken stock" or "stock"
- "Smoked paprika" should match "paprika"

Do NOT match:
- "Chicken breast" with "chicken stock" (different products)
- "Cream cheese" with "cream" (different products)

Return a match entry for every ingredient index (0-based).`,
        },
        {
          role: "user",
          content: `Recipe ingredients:\n${ingredientNames.map((n, i) => `${i}. ${n}`).join("\n")}\n\nPantry items:\n${pantryItemNames.join(", ")}`,
        },
      ],
    });

    for (const entry of object.matches) {
      if (entry.matched) {
        matched.add(entry.ingredientIndex);
      }
    }
  } catch (error) {
    logger.error("AI pantry matching failed:", error);
    // Silently fall back — no ingredients marked as in pantry
  }

  return matched;
}

export { matchIngredientsWithPantry };
