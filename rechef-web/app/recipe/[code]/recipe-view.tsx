"use client";

import { useState } from "react";

type Recipe = {
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

export function RecipeView({ recipe }: { recipe: Recipe }) {
  const [activeTab, setActiveTab] = useState<"ingredients" | "steps">(
    "ingredients",
  );

  const totalMinutes =
    (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0);

  return (
    <div className="min-h-screen bg-white">
      {/* Hero Image */}
      {recipe.imageUrl ? (
        <div className="relative w-full aspect-square max-h-[420px] overflow-hidden bg-gray-100">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={recipe.imageUrl}
            alt={recipe.name}
            className="w-full h-full object-cover"
          />
          {/* Gradient overlay at bottom for smooth transition */}
          <div className="absolute bottom-0 left-0 right-0 h-20 bg-linear-to-t from-[#F7F5F0] to-transparent" />
        </div>
      ) : (
        <div className="w-full h-52 bg-linear-to-br from-gray-50 via-gray-100 to-gray-50 flex items-center justify-center">
          <div className="flex flex-col items-center gap-2 text-gray-300">
            <svg
              width="48"
              height="48"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2z" />
              <path d="M15 9.354a4 4 0 1 0-2.646 7.023" />
            </svg>
          </div>
        </div>
      )}

      {/* Title & Meta Section — cream background matching the app */}
      <div className="bg-[#F7F5F0] px-5 py-6 space-y-4">
        {/* Shared badge — matches app's blue pill style */}
        <div className="inline-flex items-center gap-1.5 rounded-full bg-blue-50 border border-blue-200 px-3 py-1 text-xs font-medium text-blue-600">
          <svg
            width="12"
            height="12"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" />
            <polyline points="16 6 12 2 8 6" />
            <line x1="12" y1="2" x2="12" y2="15" />
          </svg>
          Shared recipe
        </div>

        {/* Recipe name */}
        <h1 className="text-[1.65rem] font-bold leading-tight tracking-tight text-gray-900">
          {recipe.name}
        </h1>

        {/* Description */}
        {recipe.description && (
          <p className="text-[0.9rem] text-gray-500 leading-relaxed">
            {recipe.description}
          </p>
        )}

        {/* Meta badges — white pills like the app */}
        <div className="flex flex-wrap gap-2">
          {totalMinutes > 0 && (
            <div className="inline-flex items-center gap-1.5 rounded-full bg-white px-3 py-1.5 text-sm font-semibold text-gray-700">
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#9CA3AF"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="12" cy="12" r="10" />
                <polyline points="12 6 12 12 16 14" />
              </svg>
              {totalMinutes} min
            </div>
          )}
          {recipe.servings != null && recipe.servings > 0 && (
            <div className="inline-flex items-center gap-1.5 rounded-full bg-white px-3 py-1.5 text-sm font-semibold text-gray-700">
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#9CA3AF"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
                <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
                <path d="M16 3.13a4 4 0 0 1 0 7.75" />
              </svg>
              {recipe.servings} servings
            </div>
          )}
        </div>
      </div>

      {/* Tab bar — pill-shaped on cream, matching the app */}
      <div className="sticky top-0 z-10 bg-white px-5 pt-5 pb-2">
        <div className="inline-flex rounded-full bg-[#F7F5F0] p-1">
          <button
            onClick={() => setActiveTab("ingredients")}
            className={`rounded-full px-5 py-2 text-sm font-semibold transition-all duration-200 ${
              activeTab === "ingredients"
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-400 hover:text-gray-600"
            }`}
          >
            Ingredients
          </button>
          <button
            onClick={() => setActiveTab("steps")}
            className={`rounded-full px-5 py-2 text-sm font-semibold transition-all duration-200 ${
              activeTab === "steps"
                ? "bg-white text-gray-900 shadow-sm"
                : "text-gray-400 hover:text-gray-600"
            }`}
          >
            Steps
          </button>
        </div>
      </div>

      {/* Tab content */}
      <div className="px-5 pt-2 pb-36">
        {activeTab === "ingredients" ? (
          <div>
            {recipe.ingredients.map((ing, idx) => (
              <div key={`${ing.name}-${idx}`}>
                <div className="flex items-center gap-3 py-3">
                  {/* Circle checkbox (visual only, matches app) */}
                  <div className="h-6 w-6 rounded-full border-[1.5px] border-gray-300 shrink-0" />

                  {/* Ingredient name */}
                  <span className="text-[0.9rem] font-medium text-gray-900 flex-1 leading-snug">
                    {ing.name}
                    {ing.notes && (
                      <span className="text-gray-400 font-normal">
                        {" "}
                        ({ing.notes})
                      </span>
                    )}
                  </span>

                  {/* Quantity — right aligned */}
                  <span className="text-[0.9rem] text-gray-500 text-right max-w-[35%] truncate shrink-0">
                    {ing.quantity}
                    {ing.unit ? ` ${ing.unit}` : ""}
                  </span>
                </div>

                {/* Divider */}
                {idx < recipe.ingredients.length - 1 && (
                  <div className="h-px bg-gray-100" />
                )}
              </div>
            ))}
          </div>
        ) : (
          <div className="space-y-5 pt-2">
            <h2 className="text-base font-semibold text-gray-900">
              Cooking Instructions
            </h2>
            {recipe.instructions.map((step, idx) => (
              <div key={idx} className="flex gap-4">
                {/* Step number circle */}
                <div className="h-8 w-8 rounded-full border border-gray-300 bg-gray-50 flex items-center justify-center shrink-0 mt-0.5">
                  <span className="text-xs font-bold text-gray-600">
                    {String(idx + 1).padStart(2, "0")}
                  </span>
                </div>

                {/* Step text */}
                <p className="text-[0.9rem] text-gray-800 leading-relaxed flex-1">
                  {step}
                </p>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Bottom CTA — fixed, with safe area for mobile */}
      <div
        className="fixed bottom-0 left-0 right-0 bg-white/80 backdrop-blur-xl border-t border-gray-100 px-5 pt-3"
        style={{ paddingBottom: "max(12px, env(safe-area-inset-bottom))" }}
      >
        <a
          href="https://rechef-ten.vercel.app"
          className="flex w-full items-center justify-center rounded-full bg-[#FF4F63] px-4 py-3.5 text-[0.9rem] font-semibold text-white shadow-lg shadow-[#FF4F63]/20 transition-all hover:brightness-110 active:scale-[0.98]"
        >
          Open in Rechef
        </a>
        <p className="text-[11px] text-gray-400 text-center mt-2">
          Save recipes, build grocery lists, and cook smarter
        </p>
      </div>
    </div>
  );
}
