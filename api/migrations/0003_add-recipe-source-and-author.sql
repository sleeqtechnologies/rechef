ALTER TABLE "recipes" ADD COLUMN "source_url" text;--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "source_title" varchar(512);--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "source_author_name" varchar(255);--> statement-breakpoint
ALTER TABLE "recipes" ADD COLUMN "source_author_avatar_url" text;
