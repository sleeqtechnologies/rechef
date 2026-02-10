CREATE TABLE "recipe_nutrition_facts" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "recipe_id" uuid NOT NULL,
  "calories_kcal" double precision,
  "protein_g" double precision,
  "carbs_g" double precision,
  "fat_g" double precision,
  "raw_json" jsonb,
  "generated_by" text,
  "createdAt" timestamp with time zone DEFAULT now() NOT NULL,
  "updatedAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "recipe_nutrition_facts"
ADD CONSTRAINT "recipe_nutrition_facts_recipe_id_recipes_id_fk"
FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id")
ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint
ALTER TABLE "recipe_nutrition_facts"
ADD CONSTRAINT "recipe_nutrition_facts_recipe_id_unique" UNIQUE("recipe_id");

