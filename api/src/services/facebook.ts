import * as cheerio from "cheerio";
import { fbdown } from "ab-downloader";
import { logger } from "../../logger";

export interface FacebookContent {
  mediaUrl: string;
  thumbnailUrl?: string;
  authorName?: string;
  caption?: string;
  title?: string;
}

interface FbdownItem {
  Normal_video?: string;
  HD?: string;
}

interface FacebookOEmbed {
  thumbnailUrl?: string;
  title?: string;
  authorName?: string;
  caption?: string;
}

async function fetchFacebookMetadata(url: string): Promise<FacebookOEmbed> {
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
    const description = $('meta[property="og:description"]')
      .attr("content")
      ?.trim();

    let authorName: string | undefined;

    if (title) {
      // Facebook titles often follow the pattern "Author Name - description"
      // or "Author Name | Facebook"
      const dashMatch = title.match(/^(.+?)\s+[-–—]\s+/);
      if (dashMatch) authorName = dashMatch[1].trim();

      if (!authorName) {
        const pipeMatch = title.match(/^(.+?)\s*\|\s*Facebook/i);
        if (pipeMatch) authorName = pipeMatch[1].trim();
      }
    }

    return {
      thumbnailUrl,
      title: title || description,
      authorName,
      caption: description,
    };
  } catch (error) {
    logger.warn("Failed to fetch Facebook metadata:", error);
    return {};
  }
}

async function parseFacebookContent(url: string): Promise<FacebookContent> {
  try {
    const [data, metadata] = await Promise.all([
      fbdown(url),
      fetchFacebookMetadata(url),
    ]);

    if (!data || (!Array.isArray(data) && typeof data !== "object")) {
      throw new Error("Facebook returned no media for this URL");
    }

    const item = (Array.isArray(data) ? data[0] : data) as FbdownItem;
    const mediaUrl = (item?.HD || item?.Normal_video)?.trim();

    if (!mediaUrl) {
      throw new Error("Could not extract media URL from Facebook");
    }

    return {
      mediaUrl,
      thumbnailUrl: metadata.thumbnailUrl,
      authorName: metadata.authorName,
      caption: metadata.caption,
      title: metadata.title,
    };
  } catch (error) {
    if (error instanceof Error) {
      if (
        error.message.startsWith("Facebook returned") ||
        error.message.startsWith("Could not extract")
      ) {
        throw error;
      }
      logger.error("Failed to parse Facebook content:", error);
      throw new Error(`Failed to parse Facebook content: ${error.message}`);
    }
    logger.error("Failed to parse Facebook content:", error);
    throw new Error("Failed to parse Facebook content");
  }
}

export { parseFacebookContent };
