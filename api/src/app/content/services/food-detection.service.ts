import OpenAI from "openai";
import { env } from "../../../../env_config";
import { logger } from "../../../../logger";

const openai = new OpenAI({
  apiKey: env.OPENAI_API_KEY,
});

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

async function detectFoodInFrame(
  imageBase64: string
): Promise<FoodDetectionResult> {
  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini",
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
              type: "image_url",
              image_url: {
                url: imageBase64,
                detail: "low",
              },
            },
          ],
        },
      ],
      max_tokens: 200,
      response_format: { type: "json_object" },
    });

    const content = response.choices[0]?.message?.content;
    if (!content) {
      return { containsFood: false, confidence: "low" };
    }

    const result = JSON.parse(content);
    return {
      containsFood: result.containsFood === true,
      description: result.description,
      confidence: result.confidence || "medium",
    };
  } catch (error) {
    logger.error("Error detecting food in frame:", error);
    return { containsFood: false, confidence: "low" };
  }
}

async function filterFoodFrames(
  frames: { base64: string; timestamp: number }[]
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
  maxFrames: number = 5
): Promise<FrameWithFood[]> {
  if (frames.length <= maxFrames) {
    return frames;
  }

  const interval = Math.floor(frames.length / maxFrames);
  const selectedFrames: FrameWithFood[] = [];

  for (let i = 0; i < frames.length && selectedFrames.length < maxFrames; i += interval) {
    selectedFrames.push(frames[i]);
  }

  return selectedFrames;
}

async function analyzeImageForFood(
  imageBase64: string
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
