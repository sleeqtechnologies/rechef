import { streamText } from "ai";
import { openai } from "@ai-sdk/openai";
import { logger } from "../../../logger";
import { Request, Response } from "express";
import * as chatRepository from "./chat.repository";
import * as recipeRepository from "../recipe/recipe.repository";

interface IngredientJson {
  name: string;
  quantity: string;
  unit?: string;
  notes?: string;
}

const formatMessage = (msg: chatRepository.ChatMessage) => ({
  id: msg.id,
  role: msg.role,
  content: msg.content,
  imageBase64: msg.imageBase64 ?? undefined,
  createdAt: msg.createdAt.toISOString(),
});

const getChatHistory = async (req: Request, res: Response) => {
  try {
    const recipeId = req.params.id as string;
    const userId = req.user.id;

    const messages = await chatRepository.findByRecipeAndUser(recipeId, userId);

    return res.status(200).json({
      messages: messages.map(formatMessage),
    });
  } catch (error) {
    logger.error("Error fetching chat history:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to fetch chat history",
    });
  }
};

const sendMessage = async (req: Request, res: Response) => {
  try {
    const recipeId = req.params.id as string;
    const userId = req.user.id;
    const { message, imageBase64, currentStep } = req.body;

    if (!message || typeof message !== "string") {
      return res.status(400).json({ error: "message is required" });
    }

    const recipe = await recipeRepository.findById(recipeId);
    if (!recipe) {
      return res.status(404).json({ error: "Recipe not found" });
    }
    if (recipe.userId !== userId) {
      return res.status(403).json({ error: "Forbidden" });
    }

    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    res.setHeader("X-Accel-Buffering", "no");
    res.flushHeaders();

    const userMsg = await chatRepository.create({
      userId,
      recipeId,
      role: "user",
      content: message,
      imageBase64: imageBase64 ?? null,
    });

    res.write(
      `event: userMessage\ndata: ${JSON.stringify(formatMessage(userMsg))}\n\n`,
    );

    const ingredients = recipe.ingredients as IngredientJson[];
    const instructions: string[] = JSON.parse(recipe.instructions);

    const ingredientList = ingredients
      .map((i) => {
        const parts = [i.quantity, i.unit, i.name].filter(Boolean);
        return `- ${parts.join(" ")}`;
      })
      .join("\n");

    const instructionList = instructions
      .map((s, i) => `${i + 1}. ${s}`)
      .join("\n");

    const currentStepInfo =
      typeof currentStep === "number" &&
      currentStep >= 0 &&
      currentStep < instructions.length
        ? `\n\nThe user is currently on step ${currentStep + 1}: "${instructions[currentStep]}"`
        : "";

    const systemPrompt = `You are a helpful cooking assistant. The user is cooking the following recipe and may need help.

Recipe: ${recipe.name}
${recipe.description ? `Description: ${recipe.description}` : ""}

Ingredients:
${ingredientList}

Instructions:
${instructionList}
${currentStepInfo}

Provide concise, practical cooking advice. If the user shares a photo of their cooking, analyze it and give feedback. Keep responses short and helpful.`;

    const recentMessages = await chatRepository.findRecentByRecipeAndUser(
      recipeId,
      userId,
      20,
    );

    const aiMessages: Array<{
      role: "user" | "assistant";
      content:
        | string
        | Array<{ type: string; text?: string; image?: string }>;
    }> = [];

    for (const msg of recentMessages) {
      if (msg.id === userMsg.id) continue;
      if (msg.role === "assistant") {
        aiMessages.push({ role: "assistant", content: msg.content });
      } else {
        aiMessages.push({ role: "user", content: msg.content });
      }
    }

    if (imageBase64) {
      aiMessages.push({
        role: "user",
        content: [
          { type: "text", text: message },
          { type: "image", image: imageBase64 },
        ],
      });
    } else {
      aiMessages.push({ role: "user", content: message });
    }

    const result = streamText({
      model: openai("gpt-4o-mini"),
      system: systemPrompt,
      messages: aiMessages as any,
    });

    let fullText = "";
    for await (const chunk of result.textStream) {
      fullText += chunk;
      res.write(
        `event: chunk\ndata: ${JSON.stringify({ text: chunk })}\n\n`,
      );
    }

    const assistantMsg = await chatRepository.create({
      userId,
      recipeId,
      role: "assistant",
      content: fullText,
    });

    res.write(
      `event: done\ndata: ${JSON.stringify({ assistantMessage: formatMessage(assistantMsg) })}\n\n`,
    );
    res.end();
  } catch (error) {
    logger.error("Error in chat:", error);
    if (res.headersSent) {
      try {
        res.write(
          `event: error\ndata: ${JSON.stringify({ error: error instanceof Error ? error.message : "Failed to process chat" })}\n\n`,
        );
      } catch (_) {
        // Connection already closed
      }
      res.end();
    } else {
      return res.status(500).json({
        error:
          error instanceof Error ? error.message : "Failed to process chat",
      });
    }
  }
};

export default { getChatHistory, sendMessage };
