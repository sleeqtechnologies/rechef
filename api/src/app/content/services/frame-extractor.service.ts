import ffmpeg from "fluent-ffmpeg";
import ffmpegInstaller from "@ffmpeg-installer/ffmpeg";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";
import { logger } from "../../../../logger";

ffmpeg.setFfmpegPath(ffmpegInstaller.path);

interface ExtractedFrame {
  path: string;
  timestamp: number;
  base64?: string;
}

interface FrameExtractionOptions {
  intervalSeconds?: number;
  maxFrames?: number;
  outputFormat?: "png" | "jpg";
}

async function downloadVideo(
  videoUrl: string,
  outputPath: string
): Promise<void> {
  const response = await fetch(videoUrl);

  if (!response.ok) {
    throw new Error(`Failed to download video: ${response.status}`);
  }

  const buffer = await response.arrayBuffer();
  fs.writeFileSync(outputPath, Buffer.from(buffer));
}

function getVideoDuration(videoPath: string): Promise<number> {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(videoPath, (err, metadata) => {
      if (err) {
        reject(err);
        return;
      }
      resolve(metadata.format.duration || 0);
    });
  });
}

async function extractFramesAtIntervals(
  videoPath: string,
  options: FrameExtractionOptions = {}
): Promise<ExtractedFrame[]> {
  const {
    intervalSeconds = 3,
    maxFrames = 20,
    outputFormat = "jpg",
  } = options;

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "frames-"));
  const frames: ExtractedFrame[] = [];

  try {
    const duration = await getVideoDuration(videoPath);
    const frameCount = Math.min(
      Math.floor(duration / intervalSeconds),
      maxFrames
    );

    const extractPromises: Promise<ExtractedFrame>[] = [];

    for (let i = 0; i < frameCount; i++) {
      const timestamp = i * intervalSeconds;
      const outputPath = path.join(tempDir, `frame_${i}.${outputFormat}`);

      extractPromises.push(
        extractSingleFrame(videoPath, timestamp, outputPath).then(() => ({
          path: outputPath,
          timestamp,
        }))
      );
    }

    const extractedFrames = await Promise.all(extractPromises);
    frames.push(...extractedFrames);

    return frames;
  } catch (error) {
    logger.error("Error extracting frames:", error);
    cleanupTempDir(tempDir);
    throw error;
  }
}

function extractSingleFrame(
  videoPath: string,
  timestampSeconds: number,
  outputPath: string
): Promise<void> {
  return new Promise((resolve, reject) => {
    ffmpeg(videoPath)
      .seekInput(timestampSeconds)
      .frames(1)
      .outputOptions(["-vf", "scale=640:-1"])
      .output(outputPath)
      .on("end", () => resolve())
      .on("error", (err) => reject(err))
      .run();
  });
}

function frameToBase64(framePath: string): string {
  const buffer = fs.readFileSync(framePath);
  const ext = path.extname(framePath).slice(1);
  const mimeType = ext === "png" ? "image/png" : "image/jpeg";
  return `data:${mimeType};base64,${buffer.toString("base64")}`;
}

async function extractFramesAsBase64(
  videoPath: string,
  options: FrameExtractionOptions = {}
): Promise<{ base64: string; timestamp: number }[]> {
  const frames = await extractFramesAtIntervals(videoPath, options);

  const base64Frames = frames.map((frame) => ({
    base64: frameToBase64(frame.path),
    timestamp: frame.timestamp,
  }));

  const tempDir = path.dirname(frames[0]?.path || "");
  if (tempDir && tempDir.includes("frames-")) {
    cleanupTempDir(tempDir);
  }

  return base64Frames;
}

async function extractFramesFromUrl(
  videoUrl: string,
  options: FrameExtractionOptions = {}
): Promise<{ base64: string; timestamp: number }[]> {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "video-"));
  const videoPath = path.join(tempDir, "video.mp4");

  try {
    await downloadVideo(videoUrl, videoPath);
    const frames = await extractFramesAsBase64(videoPath, options);
    return frames;
  } finally {
    cleanupTempDir(tempDir);
  }
}

function cleanupTempDir(dirPath: string): void {
  try {
    if (fs.existsSync(dirPath)) {
      const files = fs.readdirSync(dirPath);
      for (const file of files) {
        fs.unlinkSync(path.join(dirPath, file));
      }
      fs.rmdirSync(dirPath);
    }
  } catch (error) {
    logger.warn("Failed to cleanup temp directory:", error);
  }
}

async function downloadImageAsBase64(imageUrl: string): Promise<string> {
  const response = await fetch(imageUrl);

  if (!response.ok) {
    throw new Error(`Failed to download image: ${response.status}`);
  }

  const contentType = response.headers.get("content-type") || "image/jpeg";
  const buffer = await response.arrayBuffer();
  const base64 = Buffer.from(buffer).toString("base64");

  return `data:${contentType};base64,${base64}`;
}

export {
  extractFramesAtIntervals,
  extractFramesAsBase64,
  extractFramesFromUrl,
  extractSingleFrame,
  frameToBase64,
  downloadVideo,
  downloadImageAsBase64,
  getVideoDuration,
  cleanupTempDir,
  ExtractedFrame,
  FrameExtractionOptions,
};
