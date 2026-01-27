import { YoutubeTranscript } from "youtube-transcript";
import ytdl from "@distube/ytdl-core";
import { logger } from "../../../../logger";

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

interface YouTubeContent {
  metadata: YouTubeMetadata;
  transcript: string;
  transcriptSegments: YouTubeTranscriptSegment[];
  videoUrl: string;
}

async function getYouTubeMetadata(videoId: string): Promise<YouTubeMetadata> {
  const info = await ytdl.getBasicInfo(
    `https://www.youtube.com/watch?v=${videoId}`,
  );
  const videoDetails = info.videoDetails;

  return {
    title: videoDetails.title,
    description: videoDetails.description || "",
    thumbnailUrl:
      videoDetails.thumbnails[videoDetails.thumbnails.length - 1]?.url || "",
    durationSeconds: parseInt(videoDetails.lengthSeconds, 10),
    channelName: videoDetails.author.name,
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

async function getYouTubeVideoUrl(videoId: string): Promise<string> {
  const info = await ytdl.getInfo(`https://www.youtube.com/watch?v=${videoId}`);

  const format = ytdl.chooseFormat(info.formats, {
    quality: "lowest",
    filter: "videoandaudio",
  });

  return format.url;
}

async function parseYouTubeContent(videoId: string): Promise<YouTubeContent> {
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

function isLongVideo(durationSeconds: number): boolean {
  return durationSeconds > 120;
}

export {
  parseYouTubeContent,
  getYouTubeMetadata,
  getYouTubeTranscript,
  getYouTubeVideoUrl,
  isLongVideo,
  YouTubeContent,
  YouTubeMetadata,
  YouTubeTranscriptSegment,
};
