import { randomUUID } from "crypto";
import { logger } from "../../logger";
import admin from "./firebase";

const STORAGE_PREFIX = "recipe_images";

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

function getDownloadUrl(bucketName: string, path: string, token: string): string {
  const encodedPath = encodeURIComponent(path);
  return `https://firebasestorage.googleapis.com/v0/b/${bucketName}/o/${encodedPath}?alt=media&token=${token}`;
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
    const path = `${STORAGE_PREFIX}/${key}.${ext}`;
    const bucket = admin.storage().bucket();
    const token = randomUUID();

    await bucket.file(path).save(buffer, {
      resumable: false,
      metadata: {
        contentType,
        cacheControl: "public, max-age=31536000",
        metadata: {
          firebaseStorageDownloadTokens: token,
        },
      },
    });

    return getDownloadUrl(bucket.name, path, token);
  } catch (err) {
    logger.warn("Recipe image upload error", { key, error: err });
    return null;
  }
}
