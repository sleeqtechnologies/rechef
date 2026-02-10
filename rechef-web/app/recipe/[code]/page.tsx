import type { Metadata } from "next";
import Link from "next/link";
import { RecipeView } from "./recipe-view";

type SharedRecipeResponse = {
  recipe: {
    id: string;
    name: string;
    description: string;
    ingredients: {
      name: string;
      quantity: string;
      unit?: string;
      notes?: string;
    }[];
    instructions: string[];
    servings?: number | null;
    prepTimeMinutes?: number | null;
    cookTimeMinutes?: number | null;
    imageUrl?: string | null;
  };
  creatorId: string;
  shareCode: string;
};

type PageProps = {
  params: Promise<{ code: string }>;
};

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  const params = await props.params;
  const code = params.code;

  try {
    const res = await fetch(
      `${process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://api.rechef.app"}/share/${code}`,
      {
        // This is a public, cacheable endpoint
        next: { revalidate: 60 },
      },
    );

    if (!res.ok) {
      return {
        title: "Rechef Recipe",
      };
    }

    const data = (await res.json()) as SharedRecipeResponse;

    const title = `${data.recipe.name} · Rechef Recipe`;
    const description =
      data.recipe.description?.slice(0, 156) ??
      "View this recipe on Rechef and save it to your cookbook.";

    const image = data.recipe.imageUrl ?? "/icon.svg";

    return {
      title,
      description,
      openGraph: {
        title,
        description,
        images: [
          {
            url: image,
          },
        ],
      },
      twitter: {
        card: "summary_large_image",
        title,
        description,
        images: [image],
      },
    };
  } catch {
    return {
      title: "Rechef Recipe",
    };
  }
}

async function fetchSharedRecipe(
  code: string,
): Promise<SharedRecipeResponse | null> {
  try {
    const res = await fetch(
      `${process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://api.rechef.app"}/share/${code}`,
      {
        cache: "no-store",
      },
    );

    if (!res.ok) return null;
    return (await res.json()) as SharedRecipeResponse;
  } catch {
    return null;
  }
}

export default async function SharedRecipePage(props: PageProps) {
  const params = await props.params;
  const code = params.code;

  const data = await fetchSharedRecipe(code);

  if (!data) {
    return (
      <main className="min-h-screen bg-white flex items-center justify-center px-5">
        <div className="max-w-sm text-center space-y-4">
          <div className="mx-auto h-12 w-12 rounded-full bg-gray-100 flex items-center justify-center">
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#9CA3AF"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <circle cx="11" cy="11" r="8" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
              <line x1="8" y1="11" x2="14" y2="11" />
            </svg>
          </div>
          <h1 className="text-xl font-bold text-gray-900">Recipe not found</h1>
          <p className="text-sm text-gray-500 leading-relaxed">
            This shared recipe link may have expired or been disabled by the
            creator.
          </p>
          <Link
            href="https://rechef-ten.vercel.app"
            className="inline-flex items-center justify-center rounded-full bg-[#FF4F63] px-5 py-2.5 text-sm font-semibold text-white transition hover:brightness-110"
          >
            Learn more about Rechef
          </Link>
        </div>
      </main>
    );
  }

  const recipe = data.recipe;

  // Fire a best-effort web_view event; ignore any error
  void (async () => {
    try {
      await fetch(
        `${process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://api.rechef.app"}/share/${code}/events`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            eventType: "web_view",
          }),
        },
      );
    } catch {
      // ignore
    }
  })();

  return (
    <main className="min-h-screen bg-white flex justify-center">
      <div className="w-full max-w-lg">
        <RecipeView recipe={recipe} />
      </div>
    </main>
  );
}
