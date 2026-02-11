CREATE TABLE IF NOT EXISTS "user_onboarding" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"firebase_auth_uid" varchar(255) NOT NULL,
	"goals" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"recipe_sources" jsonb DEFAULT '[]'::jsonb NOT NULL,
	"organization_method" varchar(100),
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
