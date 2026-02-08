import * as cheerio from "cheerio";
import { igdl } from "ab-downloader";
import { logger } from "../../logger";

export interface InstagramContent {
  mediaUrl: string;
  thumbnailUrl?: string;
  authorName?: string;
  caption?: string;
  title?: string;
}

interface IgdlItem {
  url?: string;
  thumbnail?: string;
}

interface InstagramOEmbed {
  thumbnailUrl?: string;
  title?: string;
  authorName?: string;
  caption?: string;
}

async function fetchInstagramMetadata(url: string): Promise<InstagramOEmbed> {
  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        Accept:
          "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
      },
    });
    if (!response.ok) return {};
    const html = await response.text();
    const $ = cheerio.load(html);

    const ogImageRaw = $('meta[property="og:image"]').attr("content");
    let thumbnailUrl: string | undefined;
    if (ogImageRaw?.trim()) {
      try {
        thumbnailUrl = new URL(ogImageRaw, url).href;
      } catch {
        thumbnailUrl = ogImageRaw.trim();
      }
    }

    const title = $('meta[property="og:title"]').attr("content")?.trim();
    const description = $('meta[property="og:description"]').attr("content")?.trim();
    const articleAuthor = $('meta[property="article:author"]').attr("content")?.trim();

    let authorName: string | undefined;

    if (articleAuthor) {
      authorName = articleAuthor
        .replace(/^https?:\/\/(www\.)?instagram\.com\//i, "")
        .replace(/\/$/, "")
        .trim() || undefined;
    }

    if (!authorName && title) {
      const onInstaMatch = title.match(/^(.+?)\s+on Instagram:?/i);
      if (onInstaMatch) authorName = onInstaMatch[1].trim();
      if (!authorName) {
        const videoByMatch = title.match(/Video by (.+?) on Instagram/i);
        if (videoByMatch) authorName = videoByMatch[1].trim();
      }
      if (!authorName && title.includes(" • ")) {
        authorName = title.split(" • ")[0]?.trim();
      }
    }

    if (!authorName && description) {
      const descMatch = description.match(/\s-\s+([^(]+?)(?:\s*\(@[\w.]+\))?\s+on Instagram:/i);
      if (descMatch) authorName = descMatch[1].trim();
      if (!authorName) {
        const atMatch = description.match(/@([\w.]+)/);
        if (atMatch) authorName = atMatch[1];
      }
    }

    return {
      thumbnailUrl,
      title: title || description,
      authorName,
      caption: description,
    };
  } catch (error) {
    logger.warn("Failed to fetch Instagram metadata:", error);
    return {};
  }
}

async function parseInstagramContent(url: string): Promise<InstagramContent> {
  try {
    const [data, metadata] = await Promise.all([
      igdl(url),
      fetchInstagramMetadata(url),
    ]);

    if (!Array.isArray(data) || data.length === 0) {
      throw new Error("Instagram returned no media for this URL");
    }

    const item = data[0] as IgdlItem;
    const mediaUrl = item?.url?.trim();

    if (!mediaUrl) {
      throw new Error("Could not extract media URL from Instagram");
    }

    const thumbnailUrl =
      item?.thumbnail?.trim() || metadata.thumbnailUrl || undefined;

    return {
      mediaUrl,
      thumbnailUrl,
      authorName: metadata.authorName,
      caption: metadata.caption,
      title: metadata.title,
    };
  } catch (error) {
    if (error instanceof Error) {
      if (error.message.startsWith("Instagram returned") || error.message.startsWith("Could not extract")) {
        throw error;
      }
      logger.error("Failed to parse Instagram content:", error);
      throw new Error(`Failed to parse Instagram content: ${error.message}`);
    }
    logger.error("Failed to parse Instagram content:", error);
    throw new Error("Failed to parse Instagram content");
  }
}

export { parseInstagramContent };
