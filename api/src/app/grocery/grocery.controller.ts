import { logger } from "../../../logger";
import { Request, Response } from "express";
import * as groceryRepository from "./grocery.repository";
import { categorizeMany } from "../../services/ingredient-categorizer";
import { createShoppingListPage } from "../../services/instacart";

interface ItemInput {
  name: string;
  quantity?: string;
  unit?: string;
}

const formatItem = (
  item: { id: string; name: string; quantity: string | null; unit: string | null; category: string; checked: boolean; recipeId: string | null; recipeName?: string | null },
) => ({
  id: item.id,
  name: item.name,
  quantity: item.quantity,
  unit: item.unit,
  category: item.category,
  checked: item.checked,
  recipeId: item.recipeId,
  recipeName: item.recipeName ?? null,
});

const addItems = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const { recipeId, items } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: "items array is required" });
    }

    const list = await groceryRepository.findOrCreateList(userId);
    let newItems = items as ItemInput[];
    if (recipeId) {
      const existing = await groceryRepository.findByListAndRecipe(
        list.id,
        recipeId,
      );
      const existingNames = new Set(
        existing.map((e) => e.name.toLowerCase().trim()),
      );
      newItems = newItems.filter(
        (item) => !existingNames.has(item.name.toLowerCase().trim()),
      );
    }

    if (newItems.length === 0) {
      return res.status(200).json({ items: [], message: "All items already in grocery list" });
    }

    // Categorize using the shared hybrid categorizer (local keywords + AI)
    const categorized = await categorizeMany(newItems.map((i) => i.name));
    const categoryMap = new Map(
      categorized.map((c) => [c.name.toLowerCase().trim(), c.category]),
    );

    const toInsert = newItems.map((item) => ({
      groceryListId: list.id,
      recipeId: recipeId ?? null,
      name: item.name,
      quantity: item.quantity ?? null,
      unit: item.unit ?? null,
      category: categoryMap.get(item.name.toLowerCase().trim()) ?? "Other",
    }));

    const created = await groceryRepository.addItems(toInsert);

    return res.status(201).json({ items: created.map(formatItem) });
  } catch (error) {
    logger.error("Error adding grocery items:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to add grocery items",
    });
  }
};

const getItems = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const items = await groceryRepository.findItemsByUserId(userId);

    return res.status(200).json({ items: items.map(formatItem) });
  } catch (error) {
    logger.error("Error fetching grocery items:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to fetch grocery items",
    });
  }
};

const toggleItem = async (req: Request, res: Response) => {
  try {
    const itemId = req.params.itemId as string;
    const updated = await groceryRepository.toggleItem(itemId);

    if (!updated) {
      return res.status(404).json({ error: "Item not found" });
    }

    return res.status(200).json({ item: formatItem(updated) });
  } catch (error) {
    logger.error("Error toggling grocery item:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to toggle grocery item",
    });
  }
};

const deleteItem = async (req: Request, res: Response) => {
  try {
    const itemId = req.params.itemId as string;
    await groceryRepository.deleteItem(itemId);

    return res.status(200).json({ message: "Item deleted" });
  } catch (error) {
    logger.error("Error deleting grocery item:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to delete grocery item",
    });
  }
};

const clearChecked = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    await groceryRepository.clearChecked(userId);

    return res.status(200).json({ message: "Checked items cleared" });
  } catch (error) {
    logger.error("Error clearing checked items:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to clear checked items",
    });
  }
};

const createOrder = async (req: Request, res: Response) => {
  try {
    const userId = req.user.id;
    const items = await groceryRepository.findItemsByUserId(userId);

    const unchecked = items.filter((i) => !i.checked);

    if (unchecked.length === 0) {
      return res.status(400).json({
        error: "No unchecked items in your grocery list",
      });
    }

    const url = await createShoppingListPage({
      title: "My Grocery List",
      lineItems: unchecked.map((item) => ({
        name: item.name,
        ...(item.quantity ? { quantity: parseFloat(item.quantity) || 1 } : {}),
        ...(item.unit ? { unit: item.unit } : {}),
      })),
    });

    return res.status(200).json({ url });
  } catch (error) {
    logger.error("Error creating Instacart order:", error);
    return res.status(500).json({
      error:
        error instanceof Error
          ? error.message
          : "Failed to create Instacart shopping list",
    });
  }
};

export default { addItems, getItems, toggleItem, deleteItem, clearChecked, createOrder };
