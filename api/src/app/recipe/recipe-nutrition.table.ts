import {
  doublePrecision,
  jsonb,
  pgTable,
  text,
  uuid,
} from "drizzle-orm/pg-core";
import { createdAt, dbId, updatedAt } from "../../database/shared-drizzle";
import { recipeTable } from "./recipe.table";

const recipeNutritionTable = pgTable("recipe_nutrition_facts", {
  id: dbId,
  recipeId: uuid("recipe_id")
    .notNull()
    .references(() => recipeTable.id, { onDelete: "cascade" }),
  caloriesKcal: doublePrecision("calories_kcal"),
  proteinGrams: doublePrecision("protein_g"),
  carbsGrams: doublePrecision("carbs_g"),
  fatGrams: doublePrecision("fat_g"),
  rawJson: jsonb("raw_json"),
  generatedBy: text("generated_by"),
  createdAt,
  updatedAt,
});

export { recipeNutritionTable };

