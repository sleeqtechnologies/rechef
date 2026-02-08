CREATE TABLE "chat_messages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"recipe_id" uuid NOT NULL,
	"role" text NOT NULL,
	"content" text NOT NULL,
	"image_base64" text,
	"createdAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "grocery_lists" DROP CONSTRAINT "grocery_lists_recipe_id_recipes_id_fk";
--> statement-breakpoint
ALTER TABLE "grocery_list_items" ADD COLUMN "recipe_id" uuid;--> statement-breakpoint
ALTER TABLE "grocery_list_items" ADD COLUMN "category" varchar(100) DEFAULT 'Other' NOT NULL;--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "source_url" text;--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "source_title" varchar(512);--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "source_author_name" varchar(255);--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "source_author_avatar_url" text;--> statement-breakpoint
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_recipe_id_recipes_id_fk" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "grocery_list_items" ADD CONSTRAINT "grocery_list_items_recipe_id_recipes_id_fk" FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "grocery_lists" DROP COLUMN "recipe_id";