import TiktokAPI from "@tobyg74/tiktok-api-dl";
import { logger } from "../../logger";

interface TikTokMetadata {
  title: string;
  description: string;
  thumbnailUrl: string;
  authorAvatarUrl: string;
  durationSeconds: number;
  authorName: string;
  videoUrl: string;
}

interface TikTokContent {
  metadata: TikTokMetadata;
  transcript: string;
  videoUrl: string;
}

interface TikTokOEmbed {
  thumbnail_url?: string;
  author_name?: string;
  author_unique_id?: string;
  title?: string;
}


async function fetchTikTokOEmbed(url: string): Promise<TikTokOEmbed> {
  try {
    const response = await fetch(
      `https://www.tiktok.com/oembed?url=${encodeURIComponent(url)}`,
    );
    if (!response.ok) return {};
    return (await response.json()) as TikTokOEmbed;
  } catch (error) {
    logger.warn("Failed to fetch TikTok oEmbed:", error);
    return {};
  }
}

async function parseTikTokContent(url: string): Promise<TikTokContent> {
  try {
    const [result, oembed] = await Promise.all([
      TiktokAPI.Downloader(url, { version: "v3" }),
      fetchTikTokOEmbed(url),
    ]);

    if (result.status !== "success" || !result.result) {
      throw new Error("Failed to fetch TikTok video data");
    }

    const data = result.result as any;
    const videoUrl = data.videoHD || data.videoSD || data.videoWatermark || "";

    if (!videoUrl) {
      throw new Error("Could not extract video URL from TikTok");
    }

    const metadata: TikTokMetadata = {
      title: data.desc || "",
      description: data.desc || "",
      thumbnailUrl: oembed.thumbnail_url || "",
      authorAvatarUrl: data.author?.avatar || "",
      durationSeconds: data.duration || 0,
      authorName: oembed.author_name || data.author?.nickname || "",
      videoUrl: videoUrl,
    };

    return {
      metadata,
      transcript: "",
      videoUrl: videoUrl,
    };
  } catch (error) {
    logger.error("Failed to parse TikTok content:", error);
    throw new Error("Failed to parse TikTok content");
  }
}

function isLongTikTokVideo(durationSeconds: number): boolean {
  return durationSeconds > 120;
}

export { parseTikTokContent, isLongTikTokVideo, TikTokContent, TikTokMetadata };
