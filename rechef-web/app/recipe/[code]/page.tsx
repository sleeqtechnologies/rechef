import type { Metadata } from "next";
import Link from "next/link";

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

export async function generateMetadata(
  props: PageProps,
): Promise<Metadata> {
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

async function fetchSharedRecipe(code: string): Promise<SharedRecipeResponse | null> {
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
      <main className="min-h-screen bg-slate-950 text-slate-50 flex items-center justify-center px-4">
        <div className="max-w-md text-center space-y-4">
          <h1 className="text-2xl font-semibold">Recipe not found</h1>
          <p className="text-slate-400">
            This shared recipe link may have expired or been disabled by the creator.
          </p>
          <Link
            href="https://rechef.app"
            className="inline-flex items-center justify-center rounded-full bg-emerald-500 px-4 py-2 text-sm font-medium text-slate-950 hover:bg-emerald-400 transition"
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

  const totalMinutes =
    (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0);

  const storeUrl = "https://rechef.app/download";

  return (
    <main className="min-h-screen bg-slate-950 text-slate-50 flex items-center justify-center px-4 py-10">
      <div className="w-full max-w-3xl rounded-3xl border border-slate-800 bg-slate-900/60 shadow-2xl shadow-emerald-600/10 backdrop-blur-xl overflow-hidden">
        <div className="flex flex-col md:flex-row">
          <div className="md:w-1/2 relative bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
            <div className="absolute inset-0 bg-[radial-gradient(circle_at_top,_#22c55e33,_transparent_60%)]" />
            <div className="relative p-6 space-y-6">
              <div className="inline-flex items-center rounded-full bg-slate-900/70 px-3 py-1 text-xs font-medium text-emerald-300 ring-1 ring-emerald-500/40">
                Shared with you from Rechef
              </div>
              <h1 className="text-2xl md:text-3xl font-semibold leading-tight">
                {recipe.name}
              </h1>
              <p className="text-sm text-slate-300 line-clamp-4">
                {recipe.description ||
                  "Open this recipe in the Rechef app to save it to your personal cookbook, generate smart grocery lists, and match with your pantry."}
              </p>
              <div className="flex flex-wrap gap-3 text-xs text-slate-200">
                {totalMinutes > 0 && (
                  <div className="inline-flex items-center gap-1 rounded-full bg-slate-900/70 px-3 py-1 ring-1 ring-slate-700">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                    {totalMinutes} min
                  </div>
                )}
                {recipe.servings && recipe.servings > 0 && (
                  <div className="inline-flex items-center gap-1 rounded-full bg-slate-900/70 px-3 py-1 ring-1 ring-slate-700">
                    <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                    {recipe.servings} servings
                  </div>
                )}
              </div>
              <div className="space-y-3">
                <Link
                  href={storeUrl}
                  className="inline-flex w-full items-center justify-center rounded-full bg-emerald-500 px-4 py-2.5 text-sm font-semibold text-slate-950 shadow-lg shadow-emerald-500/40 hover:bg-emerald-400 transition"
                >
                  Get Rechef to save this recipe
                </Link>
                <p className="text-[11px] leading-relaxed text-slate-400">
                  Download the Rechef app to keep this recipe, generate grocery lists from
                  the ingredients, and get live updates if the creator makes changes.
                </p>
              </div>
            </div>
          </div>
          <div className="md:w-1/2 border-t md:border-t-0 md:border-l border-slate-800 bg-slate-950/60 p-6 space-y-5">
            <div>
              <h2 className="text-sm font-semibold text-slate-100 mb-2">
                Ingredients
              </h2>
              <ul className="space-y-1.5 max-h-44 overflow-y-auto pr-1 text-xs text-slate-200">
                {recipe.ingredients.map((ing) => (
                  <li key={`${ing.name}-${ing.quantity}`}>
                    <span className="text-slate-300">
                      {ing.quantity} {ing.unit}
                    </span>{" "}
                    <span>{ing.name}</span>
                    {ing.notes && (
                      <span className="text-slate-400"> — {ing.notes}</span>
                    )}
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <h2 className="text-sm font-semibold text-slate-100 mb-2">
                Steps
              </h2>
              <ol className="space-y-1.5 max-h-44 overflow-y-auto pr-1 text-xs text-slate-200 list-decimal list-inside">
                {recipe.instructions.map((step, idx) => (
                  <li key={idx}>{step}</li>
                ))}
              </ol>
            </div>
            <p className="text-[11px] text-slate-500 pt-1">
              This is a preview. For timers, pantry matching, grocery lists, and AI cooking
              help, open this recipe in the Rechef mobile app.
            </p>
          </div>
        </div>
      </div>
    </main>
  );
}

