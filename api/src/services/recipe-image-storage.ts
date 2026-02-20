import { createClient } from "@supabase/supabase-js";
import { env } from "../../env_config";
import { logger } from "../../logger";

const BUCKET = "recipe_images";

const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false },
});

function getExtensionFromMime(mime: string): string {
  const map: Record<string, string> = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
    "image/webp": "webp",
    "image/gif": "gif",
  };
  return map[mime] ?? "jpg";
}


export async function uploadRecipeImage(
  imageUrlOrDataUrl: string,
  key: string,
): Promise<string | null> {
  try {
    let buffer: Buffer;
    let contentType: string;

    if (imageUrlOrDataUrl.startsWith("data:")) {
      const match = imageUrlOrDataUrl.match(/^data:(image\/[a-z]+);base64,(.+)$/i);
      if (!match) return null;
      contentType = match[1];
      const base64 = match[2];
      buffer = Buffer.from(base64, "base64");
    } else {
      const response = await fetch(imageUrlOrDataUrl, {
        headers: { Accept: "image/*" },
      });
      if (!response.ok) return null;
      contentType = response.headers.get("content-type")?.split(";")[0] ?? "image/jpeg";
      const arrayBuffer = await response.arrayBuffer();
      buffer = Buffer.from(arrayBuffer);
    }

    const ext = getExtensionFromMime(contentType);
    const path = `${key}.${ext}`;

    const { error } = await supabase.storage.from(BUCKET).upload(path, buffer, {
      contentType,
      upsert: true,
    });

    if (error) {
      logger.warn("Recipe image upload failed", { key, error: error.message });
      return null;
    }

    const {
      data: { publicUrl },
    } = supabase.storage.from(BUCKET).getPublicUrl(path);
    return publicUrl;
  } catch (err) {
    logger.warn("Recipe image upload error", { key, error: err });
    return null;
  }
}
