import { generateObject } from "ai";
import { openai } from "@ai-sdk/openai";
import { z } from "zod";
import { logger } from "../../logger";

interface FrameWithFood {
  base64: string;
  timestamp: number;
  containsFood: boolean;
  foodDescription?: string;
}

interface FoodDetectionResult {
  containsFood: boolean;
  description?: string;
  confidence: "high" | "medium" | "low";
}

const foodDetectionSchema = z.object({
  containsFood: z.boolean().default(false),
  description: z.string().optional(),
  confidence: z.enum(["high", "medium", "low"]).default("medium"),
});

async function detectFoodInFrame(
  imageBase64: string,
): Promise<FoodDetectionResult> {
  try {
    const { object } = await generateObject({
      model: openai("gpt-5.2"),
      schema: foodDetectionSchema,
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: `Analyze this image and determine if it contains food or cooking-related content.
              
Respond in JSON format:
{
  "containsFood": boolean,
  "description": "brief description of what food/cooking is shown, if any",
  "confidence": "high" | "medium" | "low"
}

Only set containsFood to true if:
- There is actual food visible in the image
- There is cooking/food preparation happening
- There are ingredients being prepared

Set containsFood to false for:
- People talking without food visible
- Empty scenes or transitions
- Non-food related content`,
            },
            {
              type: "image",
              image: imageBase64,
            },
          ],
        },
      ],
    });

    return {
      containsFood: object.containsFood === true,
      description: object.description,
      confidence: object.confidence || "medium",
    };
  } catch (error) {
    logger.error("Error detecting food in frame:", error);
    return { containsFood: false, confidence: "low" };
  }
}

async function filterFoodFrames(
  frames: { base64: string; timestamp: number }[],
): Promise<FrameWithFood[]> {
  const results: FrameWithFood[] = [];

  const batchSize = 5;
  for (let i = 0; i < frames.length; i += batchSize) {
    const batch = frames.slice(i, i + batchSize);

    const detectionPromises = batch.map(async (frame) => {
      const detection = await detectFoodInFrame(frame.base64);
      return {
        ...frame,
        containsFood: detection.containsFood,
        foodDescription: detection.description,
      };
    });

    const batchResults = await Promise.all(detectionPromises);
    results.push(...batchResults);
  }

  return results.filter((frame) => frame.containsFood);
}

async function selectBestFoodFrames(
  frames: FrameWithFood[],
  maxFrames: number = 5,
): Promise<FrameWithFood[]> {
  if (frames.length <= maxFrames) {
    return frames;
  }

  const interval = Math.floor(frames.length / maxFrames);
  const selectedFrames: FrameWithFood[] = [];

  for (
    let i = 0;
    i < frames.length && selectedFrames.length < maxFrames;
    i += interval
  ) {
    selectedFrames.push(frames[i]);
  }

  return selectedFrames;
}

async function analyzeImageForFood(
  imageBase64: string,
): Promise<{ containsFood: boolean; description: string }> {
  const result = await detectFoodInFrame(imageBase64);
  return {
    containsFood: result.containsFood,
    description: result.description || "",
  };
}

export {
  detectFoodInFrame,
  filterFoodFrames,
  selectBestFoodFrames,
  analyzeImageForFood,
  FoodDetectionResult,
  FrameWithFood,
};
