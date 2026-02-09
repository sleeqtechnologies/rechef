import ffmpeg from "fluent-ffmpeg";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";
import { logger } from "../../logger";

const NO_FFMPEG_MESSAGE =
  "Video frame extraction is unavailable (ffmpeg/ffprobe not installed). On Vercel, ensure onlyBuiltDependencies includes @ffmpeg-installer/linux-x64 and @ffprobe-installer/linux-x64 in pnpm-workspace.yaml.";

let ffmpegReady = false;
let ffmpegInitError: Error | null = null;

function ensureFfmpegReady(): void {
  if (ffmpegReady) return;
  if (ffmpegInitError) throw ffmpegInitError;
  try {
    const ffmpegInstaller = require("@ffmpeg-installer/ffmpeg");
    const ffprobeInstaller = require("@ffprobe-installer/ffprobe");
    ffmpeg.setFfmpegPath(ffmpegInstaller.path);
    ffmpeg.setFfprobePath(ffprobeInstaller.path);
    ffmpegReady = true;
  } catch (err) {
    ffmpegInitError =
      err instanceof Error ? err : new Error(String(err));
    const code = (err as { code?: string }).code;
    if (code === "MODULE_NOT_FOUND") {
      ffmpegInitError = new Error(NO_FFMPEG_MESSAGE);
    }
    throw ffmpegInitError;
  }
}

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
  outputPath: string,
): Promise<void> {
  const response = await fetch(videoUrl);

  if (!response.ok) {
    throw new Error(`Failed to download video: ${response.status}`);
  }


  const fileStream = fs.createWriteStream(outputPath);

  const body = response.body;
  if (!body) {
    throw new Error("Response body is null while downloading video");
  }

  for await (const chunk of body as any) {
    fileStream.write(chunk);
  }

  await new Promise<void>((resolve, reject) => {
    fileStream.end();
    fileStream.on("finish", () => resolve());
    fileStream.on("error", (err) => reject(err));
  });
}

function getVideoDuration(videoPath: string): Promise<number> {
  ensureFfmpegReady();
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
  options: FrameExtractionOptions = {},
): Promise<ExtractedFrame[]> {
  ensureFfmpegReady();
  const { intervalSeconds = 3, maxFrames = 20, outputFormat = "jpg" } = options;

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "frames-"));
  const frames: ExtractedFrame[] = [];

  try {
    const duration = await getVideoDuration(videoPath);
    const frameCount = Math.min(
      Math.floor(duration / intervalSeconds),
      maxFrames,
    );

    const extractPromises: Promise<ExtractedFrame>[] = [];

    for (let i = 0; i < frameCount; i++) {
      const timestamp = i * intervalSeconds;
      const outputPath = path.join(tempDir, `frame_${i}.${outputFormat}`);

      extractPromises.push(
        extractSingleFrame(videoPath, timestamp, outputPath).then(() => ({
          path: outputPath,
          timestamp,
        })),
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
  outputPath: string,
): Promise<void> {
  ensureFfmpegReady();
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
  options: FrameExtractionOptions = {},
): Promise<{ base64: string; timestamp: number }[]> {
  const frames = await extractFramesAtIntervals(videoPath, options);
  const tempDir = path.dirname(frames[0]?.path || "");


  const base64Frames: { base64: string; timestamp: number }[] = [];

  for (const frame of frames) {
    const base64 = frameToBase64(frame.path);
    base64Frames.push({
      base64,
      timestamp: frame.timestamp,
    });
    try {
      if (fs.existsSync(frame.path)) {
        fs.unlinkSync(frame.path);
      }
    } catch (err) {
      logger.warn("Failed to delete frame file:", err);
    }
  }

  // Clean up the temp directory
  if (tempDir && tempDir.includes("frames-")) {
    cleanupTempDir(tempDir);
  }

  return base64Frames;
}

async function extractFramesFromUrl(
  videoUrl: string,
  options: FrameExtractionOptions = {},
): Promise<{ base64: string; timestamp: number }[]> {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "video-"));
  const videoPath = path.join(tempDir, "video.mp4");

  try {
    await downloadVideo(videoUrl, videoPath);
    const frames = await extractFramesAsBase64(videoPath, options);
 
    try {
      if (fs.existsSync(videoPath)) {
        fs.unlinkSync(videoPath);
      }
    } catch (err) {
      logger.warn("Failed to delete video file:", err);
    }
    
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
