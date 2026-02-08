import { logger } from "../../../logger";
import { Request, Response } from "express";
import * as pantryRepository from "./pantry.repository";
import { categorize, classifyWithAI } from "../../services/ingredient-categorizer";

const formatItem = (item: pantryRepository.PantryItem) => ({
  id: item.id,
  name: item.name,
  category: item.category,
});

const addItems = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const { items } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res
        .status(400)
        .json({ error: "items must be a non-empty array of strings" });
    }

    const parsed: { userId: string; name: string; category: string }[] = items
      .map((name: string) => String(name).trim())
      .filter((name: string) => name.length > 0)
      .map((name: string) => ({
        userId,
        name,
        category: categorize(name) as string,
      }));

    if (parsed.length === 0) {
      return res.status(400).json({ error: "No valid item names provided" });
    }

    const unknowns = parsed.filter((i) => i.category === "Other");
    if (unknowns.length > 0) {
      const aiResults = await classifyWithAI(unknowns.map((i) => i.name));
      for (const item of unknowns) {
        const aiCategory = aiResults.get(item.name.toLowerCase().trim());
        if (aiCategory && aiCategory !== "Other") {
          item.category = aiCategory;
        }
      }
    }

    const created = await pantryRepository.createMany(parsed);

    return res.status(201).json({ items: created.map(formatItem) });
  } catch (error) {
    logger.error("Error adding pantry items:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to add pantry items",
    });
  }
};

const getItems = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const items = await pantryRepository.findAllByUserId(userId);

    return res.status(200).json({ items: items.map(formatItem) });
  } catch (error) {
    logger.error("Error fetching pantry items:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to fetch pantry items",
    });
  }
};

const deleteItem = async (req: Request, res: Response) => {
  try {
    const id = req.params.id as string;
    const item = await pantryRepository.findById(id);

    if (!item) {
      return res.status(404).json({ error: "Pantry item not found" });
    }

    if (item.userId !== req.user.id) {
      return res.status(403).json({ error: "Forbidden" });
    }

    await pantryRepository.deleteById(id);
    return res.status(200).json({ message: "Pantry item deleted" });
  } catch (error) {
    logger.error("Error deleting pantry item:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to delete pantry item",
    });
  }
};

export default { addItems, getItems, deleteItem };
