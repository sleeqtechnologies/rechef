import { YoutubeTranscript } from "youtube-transcript";
import ytdl from "@distube/ytdl-core";
import { env } from "../../env_config";
import { logger } from "../../logger";

interface YouTubeMetadata {
  title: string;
  description: string;
  thumbnailUrl: string;
  durationSeconds: number;
  channelName: string;
}

interface YouTubeTranscriptSegment {
  text: string;
  offset: number;
  duration: number;
}

interface YouTubeShortContent {
  metadata: YouTubeMetadata;
  transcript: string;
  transcriptSegments: YouTubeTranscriptSegment[];
  videoUrl: string | null;
}

interface YouTubeVideoContent {
  metadata: YouTubeMetadata;
  transcript: string;
  transcriptSegments: YouTubeTranscriptSegment[];
}

/** Parse ISO 8601 duration (e.g. PT5M30S) to seconds */
function parseDuration(isoDuration: string): number {
  const match = isoDuration.match(/PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?/);
  if (!match) return 0;
  const hours = parseInt(match[1] || "0", 10);
  const minutes = parseInt(match[2] || "0", 10);
  const seconds = parseInt(match[3] || "0", 10);
  return hours * 3600 + minutes * 60 + seconds;
}

async function fetchMetadataViaApi(
  videoId: string,
  apiKey: string,
): Promise<YouTubeMetadata | null> {
  try {
    const url = new URL("https://www.googleapis.com/youtube/v3/videos");
    url.searchParams.set("part", "snippet,contentDetails");
    url.searchParams.set("id", videoId);
    url.searchParams.set("key", apiKey);

    const response = await fetch(url.toString());
    if (!response.ok) {
      logger.warn(`YouTube API returned ${response.status} for video ${videoId}`);
      return null;
    }

    const data = (await response.json()) as {
      items?: Array<{
        snippet?: {
          title?: string;
          description?: string;
          channelTitle?: string;
          thumbnails?: Record<string, { url?: string }>;
        };
        contentDetails?: { duration?: string };
      }>;
    };

    const item = data.items?.[0];
    if (!item?.snippet) return null;

    const snippet = item.snippet;
    const thumbnails = snippet.thumbnails;
    const thumbnailUrl =
      thumbnails?.maxres?.url ||
      thumbnails?.high?.url ||
      thumbnails?.medium?.url ||
      thumbnails?.default?.url ||
      "";

    const durationSeconds = item.contentDetails?.duration
      ? parseDuration(item.contentDetails.duration)
      : 0;

    return {
      title: snippet.title || "Untitled",
      description: snippet.description || "",
      thumbnailUrl,
      durationSeconds,
      channelName: snippet.channelTitle || "",
    };
  } catch (error) {
    logger.warn(`YouTube API fetch failed for ${videoId}:`, error);
    return null;
  }
}

async function fetchMetadataViaOEmbed(
  videoId: string,
): Promise<YouTubeMetadata | null> {
  try {
    const url = `https://www.youtube.com/watch?v=${videoId}`;
    const oembedUrl = `https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`;

    const response = await fetch(oembedUrl);
    if (!response.ok) return null;

    const data = (await response.json()) as {
      title?: string;
      author_name?: string;
      thumbnail_url?: string;
    };

    return {
      title: data.title || "Untitled",
      description: "",
      thumbnailUrl: data.thumbnail_url || "",
      durationSeconds: 0,
      channelName: data.author_name || "",
    };
  } catch (error) {
    logger.warn(`YouTube oEmbed fetch failed for ${videoId}:`, error);
    return null;
  }
}

async function fetchMetadataViaYtdl(videoId: string): Promise<YouTubeMetadata | null> {
  try {
    const info = await ytdl.getBasicInfo(
      `https://www.youtube.com/watch?v=${videoId}`,
    );
    const videoDetails = info?.videoDetails;
    if (!videoDetails) return null;

    const thumbnails = videoDetails.thumbnails;
    const thumbnailUrl =
      thumbnails?.[thumbnails.length - 1]?.url || "";

    return {
      title: videoDetails.title || "Untitled",
      description: videoDetails.description || "",
      thumbnailUrl,
      durationSeconds: parseInt(videoDetails.lengthSeconds || "0", 10),
      channelName: videoDetails.author?.name || "",
    };
  } catch (error) {
    logger.warn(`ytdl-core metadata fetch failed for ${videoId}:`, error);
    return null;
  }
}

async function getYouTubeMetadata(videoId: string): Promise<YouTubeMetadata> {
  const apiKey = env.YOUTUBE_API_KEY?.trim();

  if (apiKey) {
    const metadata = await fetchMetadataViaApi(videoId, apiKey);
    if (metadata) return metadata;
  }

  const ytdlMetadata = await fetchMetadataViaYtdl(videoId);
  if (ytdlMetadata) return ytdlMetadata;

  const oembedMetadata = await fetchMetadataViaOEmbed(videoId);
  if (oembedMetadata) return oembedMetadata;

  return {
    title: "Untitled",
    description: "",
    thumbnailUrl: "",
    durationSeconds: 0,
    channelName: "",
  };
}

async function getYouTubeTranscript(
  videoId: string,
): Promise<{ transcript: string; segments: YouTubeTranscriptSegment[] }> {
  try {
    const transcriptData = await YoutubeTranscript.fetchTranscript(videoId);

    const segments: YouTubeTranscriptSegment[] = transcriptData.map(
      (segment) => ({
        text: segment.text,
        offset: segment.offset,
        duration: segment.duration,
      }),
    );

    const fullTranscript = segments.map((s) => s.text).join(" ");

    return {
      transcript: fullTranscript,
      segments,
    };
  } catch (error) {
    logger.warn(`Could not fetch transcript for video ${videoId}:`, error);
    return {
      transcript: "",
      segments: [],
    };
  }
}

async function getYouTubeVideoUrl(videoId: string): Promise<string | null> {
  try {
    const info = await ytdl.getInfo(
      `https://www.youtube.com/watch?v=${videoId}`,
    );

    const format = ytdl.chooseFormat(info.formats, {
      quality: "lowest",
      filter: "videoandaudio",
    });

    return format?.url ?? null;
  } catch (error) {
    logger.warn(`Could not get video URL for ${videoId}:`, error);
    return null;
  }
}

async function parseYouTubeShort(videoId: string): Promise<YouTubeShortContent> {
  const [metadata, transcriptData, videoUrl] = await Promise.all([
    getYouTubeMetadata(videoId),
    getYouTubeTranscript(videoId),
    getYouTubeVideoUrl(videoId),
  ]);

  return {
    metadata,
    transcript: transcriptData.transcript,
    transcriptSegments: transcriptData.segments,
    videoUrl,
  };
}

async function parseYouTubeVideo(videoId: string): Promise<YouTubeVideoContent> {
  const [metadata, transcriptData] = await Promise.all([
    getYouTubeMetadata(videoId),
    getYouTubeTranscript(videoId),
  ]);

  return {
    metadata,
    transcript: transcriptData.transcript,
    transcriptSegments: transcriptData.segments,
  };
}

export {
  parseYouTubeShort,
  parseYouTubeVideo,
  getYouTubeMetadata,
  getYouTubeTranscript,
  getYouTubeVideoUrl,
  YouTubeShortContent,
  YouTubeVideoContent,
  YouTubeMetadata,
  YouTubeTranscriptSegment,
};
