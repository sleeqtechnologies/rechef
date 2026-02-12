import { logger } from "../../../logger";
import { Request, Response } from "express";
import * as pantryRepository from "./pantry.repository";
import { categorizeMany } from "../../services/ingredient-categorizer";
import { searchFoodImages } from "../../services/image-search";

const formatItem = (item: pantryRepository.PantryItem) => ({
  id: item.id,
  name: item.name,
  category: item.category,
  imageUrl: item.imageUrl ?? null,
});

async function fetchImageForItem(name: string): Promise<string | null> {
  try {
    const urls = await searchFoodImages(`${name} food`, 1, "small");
    return urls[0] ?? null;
  } catch {
    return null;
  }
}

const addItems = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const { items } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res
        .status(400)
        .json({ error: "items must be a non-empty array of strings" });
    }

    const categorized = await categorizeMany(
      items.map((name: string) => String(name)),
    );

    if (categorized.length === 0) {
      return res.status(400).json({ error: "No valid item names provided" });
    }

    const imageResults = await Promise.allSettled(
      categorized.map((i) => fetchImageForItem(i.name)),
    );

    const parsed = categorized.map((i, idx) => ({
      userId,
      name: i.name,
      category: i.category,
      imageUrl:
        imageResults[idx].status === "fulfilled"
          ? imageResults[idx].value
          : null,
    }));

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

    const missingImages = items.filter((i) => !i.imageUrl);
    if (missingImages.length > 0) {
      await Promise.allSettled(
        missingImages.map(async (item) => {
          const url = await fetchImageForItem(item.name);
          if (url) {
            await pantryRepository.updateImageUrl(item.id, url);
            item.imageUrl = url;
          }
        }),
      );
    }

    return res.status(200).json({ items: items.map(formatItem) });
  } catch (error) {
    logger.error("Error fetching pantry items:", error);
    return res.status(500).json({
      error:
        error instanceof Error ? error.message : "Failed to fetch pantry items",
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
        error instanceof Error ? error.message : "Failed to delete pantry item",
    });
  }
};

const getImages = async (req: Request, res: Response) => {
  try {
    const { names } = req.body;

    if (!names || !Array.isArray(names) || names.length === 0) {
      return res
        .status(400)
        .json({ error: "names must be a non-empty array of strings" });
    }

    const limited = names.slice(0, 50).map((n: string) => String(n).trim());

    const results = await Promise.allSettled(
      limited.map(async (name) => {
        const url = await fetchImageForItem(name);
        return { name, imageUrl: url };
      }),
    );

    const images: Record<string, string | null> = {};
    for (const result of results) {
      if (result.status === "fulfilled") {
        images[result.value.name] = result.value.imageUrl;
      }
    }

    return res.status(200).json({ images });
  } catch (error) {
    logger.error("Error fetching pantry images:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to fetch pantry images",
    });
  }
};

export default { addItems, getItems, getImages, deleteItem };
