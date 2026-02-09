ALTER TABLE "grocery_list_items" DROP CONSTRAINT "grocery_list_items_recipe_id_recipes_id_fk";--> statement-breakpoint
ALTER TABLE "grocery_list_items" ADD CONSTRAINT "grocery_list_items_recipe_id_recipes_id_fk" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
