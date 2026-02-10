CREATE TABLE "shared_recipes" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "recipe_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "share_code" varchar(12) NOT NULL,
  "is_active" boolean NOT NULL DEFAULT true,
  "createdAt" timestamp with time zone DEFAULT now() NOT NULL,
  "updatedAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "shared_recipes"
ADD CONSTRAINT "shared_recipes_recipe_id_recipes_id_fk"
FOREIGN KEY ("recipe_id") REFERENCES "public"."recipes"("id")
ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint
ALTER TABLE "shared_recipes"
ADD CONSTRAINT "shared_recipes_user_id_users_id_fk"
FOREIGN KEY ("user_id") REFERENCES "public"."users"("id")
ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint
ALTER TABLE "shared_recipes"
ADD CONSTRAINT "shared_recipes_recipe_id_unique" UNIQUE("recipe_id");
--> statement-breakpoint
ALTER TABLE "shared_recipes"
ADD CONSTRAINT "shared_recipes_share_code_unique" UNIQUE("share_code");

--> statement-breakpoint
CREATE TABLE "shared_recipe_saves" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "shared_recipe_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "createdAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "shared_recipe_saves"
ADD CONSTRAINT "shared_recipe_saves_shared_recipe_id_shared_recipes_id_fk"
FOREIGN KEY ("shared_recipe_id") REFERENCES "public"."shared_recipes"("id")
ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint
ALTER TABLE "shared_recipe_saves"
ADD CONSTRAINT "shared_recipe_saves_user_id_users_id_fk"
FOREIGN KEY ("user_id") REFERENCES "public"."users"("id")
ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint
ALTER TABLE "shared_recipe_saves"
ADD CONSTRAINT "shared_recipe_saves_unique_subscription" UNIQUE("shared_recipe_id","user_id");

--> statement-breakpoint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'share_event_type'
  ) THEN
    CREATE TYPE "share_event_type" AS ENUM (
      'web_view',
      'app_open',
      'app_install',
      'recipe_save',
      'grocery_add',
      'grocery_purchase'
    );
  END IF;
END $$;

--> statement-breakpoint
CREATE TABLE "share_events" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
  "shared_recipe_id" uuid NOT NULL,
  "event_type" "share_event_type" NOT NULL,
  "user_id" uuid,
  "metadata" jsonb,
  "ip_hash" varchar(255),
  "createdAt" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "share_events"
ADD CONSTRAINT "share_events_shared_recipe_id_shared_recipes_id_fk"
FOREIGN KEY ("shared_recipe_id") REFERENCES "public"."shared_recipes"("id")
ON DELETE cascade ON UPDATE no action;
--> statement-breakpoint
ALTER TABLE "share_events"
ADD CONSTRAINT "share_events_user_id_users_id_fk"
FOREIGN KEY ("user_id") REFERENCES "public"."users"("id")
ON DELETE cascade ON UPDATE no action;

