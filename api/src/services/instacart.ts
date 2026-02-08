import { env } from "../../env_config";
import { logger } from "../../logger";

const INSTACART_BASE_URL = "https://connect.dev.instacart.tools";

interface LineItem {
  name: string;
  quantity?: number;
  unit?: string;
}

interface CreateShoppingListParams {
  title: string;
  lineItems: LineItem[];
}

async function createShoppingListPage(
  params: CreateShoppingListParams,
): Promise<string> {
  const body = {
    title: params.title,
    link_type: "shopping_list",
    line_items: params.lineItems.map((item) => ({
      name: item.name,
      ...(item.quantity != null ? { quantity: item.quantity } : {}),
      ...(item.unit ? { unit: item.unit } : {}),
    })),
    landing_page_configuration: {
      enable_pantry_items: true,
    },
  };

  const response = await fetch(
    `${INSTACART_BASE_URL}/idp/v1/products/products_link`,
    {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.INSTACART_API_KEY}`,
      },
      body: JSON.stringify(body),
    },
  );

  if (!response.ok) {
    const errorText = await response.text();
    logger.error("Instacart API error:", {
      status: response.status,
      body: errorText,
    });
    throw new Error(`Instacart API returned ${response.status}: ${errorText}`);
  }

  const data = (await response.json()) as { products_link_url: string };
  return data.products_link_url;
}

export { createShoppingListPage };
export type { LineItem, CreateShoppingListParams };
