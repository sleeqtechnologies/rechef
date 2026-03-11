"use client";

import { useEffect, useRef, useState } from "react";

const rechefHomeUrl = "https://rechef-ten.vercel.app";
const iosAppStoreUrl = "https://apps.apple.com/ca/app/rechef/id6758213347";
const androidFallbackUrl = "https://onelink.to/b5bcjh";
const appOpenScheme = "com.rechef.app";
const appOpenDelayMs = 150;
const storeRedirectDelayMs = 1200;

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

type RecipeViewProps = {
  recipe: Recipe;
  shareCode: string;
  apiBaseUrl: string;
};

function detectMobilePlatform(): "ios" | "android" | null {
  if (typeof window === "undefined") {
    return null;
  }

  const userAgent = window.navigator.userAgent;
  if (/bot|crawl|spider|facebookexternalhit|slurp/i.test(userAgent)) {
    return null;
  }

  const isAppleMobile =
    /iPhone|iPad|iPod/i.test(userAgent) ||
    (window.navigator.platform === "MacIntel" &&
      window.navigator.maxTouchPoints > 1);

  if (isAppleMobile) {
    return "ios";
  }

  if (/Android/i.test(userAgent)) {
    return "android";
  }

  return null;
}

function getFallbackTarget(platform: "ios" | "android" | null): string | null {
  if (platform === "ios") {
    return iosAppStoreUrl;
  }

  if (platform === "android") {
    return androidFallbackUrl;
  }

  return null;
}

function getOpenAppUrl(shareCode: string): string {
  return `${appOpenScheme}://shared-recipe/${encodeURIComponent(shareCode)}`;
}

function getRedirectSessionKey(shareCode: string): string {
  return `rechef:share-store-redirect:${shareCode}`;
}

export function RecipeView({ recipe, shareCode, apiBaseUrl }: RecipeViewProps) {
  const [activeTab, setActiveTab] = useState<"ingredients" | "steps">(
    "ingredients",
  );
  const hasTrackedWebViewRef = useRef(false);
  const hasTriggeredStoreRedirectRef = useRef(false);

  const totalMinutes =
    (recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0);

  useEffect(() => {
    if (hasTrackedWebViewRef.current) {
      return;
    }

    hasTrackedWebViewRef.current = true;
    const body = JSON.stringify({ eventType: "web_view" });
    const endpoint = `${apiBaseUrl}/share/${shareCode}/events`;

    if (typeof window.navigator.sendBeacon === "function") {
      const blob = new Blob([body], { type: "application/json" });
      if (window.navigator.sendBeacon(endpoint, blob)) {
        return;
      }
    }

    void fetch(endpoint, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body,
      keepalive: true,
    }).catch(() => {
      // Best-effort analytics only.
    });
  }, [apiBaseUrl, shareCode]);

  useEffect(() => {
    const platform = detectMobilePlatform();
    const fallbackTarget = getFallbackTarget(platform);
    if (!platform || !fallbackTarget) {
      return;
    }

    try {
      if (window.sessionStorage.getItem(getRedirectSessionKey(shareCode))) {
        return;
      }
    } catch {
      // Ignore storage failures.
    }

    const openTimer = window.setTimeout(() => {
      window.location.assign(getOpenAppUrl(shareCode));

      window.setTimeout(() => {
        if (document.visibilityState !== "visible") {
          return;
        }

        if (hasTriggeredStoreRedirectRef.current) {
          return;
        }

        hasTriggeredStoreRedirectRef.current = true;
        try {
          window.sessionStorage.setItem(getRedirectSessionKey(shareCode), "1");
        } catch {
          // Ignore storage failures.
        }

        const body = JSON.stringify({
          eventType: "app_install",
          metadata: {
            platform,
            trigger: "auto_fallback",
            destination: fallbackTarget,
          },
        });
        const endpoint = `${apiBaseUrl}/share/${shareCode}/events`;

        if (typeof window.navigator.sendBeacon === "function") {
          const blob = new Blob([body], { type: "application/json" });
          window.navigator.sendBeacon(endpoint, blob);
        } else {
          void fetch(endpoint, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body,
            keepalive: true,
          }).catch(() => {
            // Ignore redirect analytics failures.
          });
        }

        window.setTimeout(() => {
          window.location.replace(fallbackTarget);
        }, 80);
      }, storeRedirectDelayMs);
    }, appOpenDelayMs);

    return () => {
      window.clearTimeout(openTimer);
    };
  }, [apiBaseUrl, shareCode]);

  function handleOpenInAppClick(event: React.MouseEvent<HTMLAnchorElement>) {
    const platform = detectMobilePlatform();
    const fallbackTarget = getFallbackTarget(platform);
    if (!platform || !fallbackTarget) {
      return;
    }

    event.preventDefault();
    window.location.assign(getOpenAppUrl(shareCode));

    window.setTimeout(() => {
      if (document.visibilityState !== "visible") {
        return;
      }

      const body = JSON.stringify({
        eventType: "app_install",
        metadata: {
          platform,
          trigger: "manual_cta",
          destination: fallbackTarget,
        },
      });
      const endpoint = `${apiBaseUrl}/share/${shareCode}/events`;

      if (typeof window.navigator.sendBeacon === "function") {
        const blob = new Blob([body], { type: "application/json" });
        window.navigator.sendBeacon(endpoint, blob);
      } else {
        void fetch(endpoint, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body,
          keepalive: true,
        }).catch(() => {
          // Ignore redirect analytics failures.
        });
      }

      window.location.replace(fallbackTarget);
    }, storeRedirectDelayMs);
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Hero Image */}
      {recipe.imageUrl ? (
        <div className="relative w-full aspect-square max-h-105 overflow-hidden bg-gray-100">
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
                viewBox="0 0 16 16"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <g clipPath="url(#clip-clock)">
                  <path
                    d="M7.99992 14.6667C11.6818 14.6667 14.6666 11.6819 14.6666 8.00004C14.6666 4.31814 11.6818 1.33337 7.99992 1.33337C4.31802 1.33337 1.33325 4.31814 1.33325 8.00004C1.33325 11.6819 4.31802 14.6667 7.99992 14.6667Z"
                    stroke="#9CA3AF"
                  />
                  <path
                    opacity="0.4"
                    d="M7.99731 6.99922C7.44505 6.99922 6.99731 7.44696 6.99731 7.99922C6.99731 8.55149 7.44505 8.99922 7.99731 8.99922C8.54958 8.99922 8.99731 8.55149 8.99731 7.99922C8.99731 7.44696 8.54958 6.99922 7.99731 6.99922ZM7.99731 6.99922V4.65979M10.0019 10.007L8.70285 8.70789"
                    stroke="#9CA3AF"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </g>
                <defs>
                  <clipPath id="clip-clock">
                    <rect width="16" height="16" fill="white" />
                  </clipPath>
                </defs>
              </svg>
              {totalMinutes} min
            </div>
          )}
          {recipe.servings != null && recipe.servings > 0 && (
            <div className="inline-flex items-center gap-1.5 rounded-full bg-white px-3 py-1.5 text-sm font-semibold text-gray-700">
              <svg
                width="16"
                height="16"
                viewBox="0 0 16 16"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <g clipPath="url(#clip-servings)">
                  <path
                    d="M2.66675 9.33337H14.6667"
                    stroke="#9CA3AF"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  <path
                    d="M3.33325 14.6667L3.95363 14.0463C4.30614 13.6938 4.48239 13.5176 4.70448 13.4174C4.92657 13.3171 5.17535 13.3016 5.6729 13.2705L7.84119 13.135C8.90685 13.0684 9.43972 13.035 9.90859 12.8099C10.3775 12.5847 10.7367 12.1896 11.4549 11.3996L13.3333 9.33337H10.9999L9.80465 10.5286C9.72519 10.6081 9.68539 10.6479 9.64405 10.683C9.43139 10.8636 9.16739 10.973 8.88932 10.9956C8.83519 11 8.77899 11 8.66659 11M8.66659 11C8.66659 10.6902 8.66659 10.5354 8.64099 10.4066C8.53579 9.87764 8.12232 9.46417 7.59339 9.35897C7.46459 9.33337 7.30972 9.33337 6.99992 9.33337H6.47891C5.78222 9.33337 5.43387 9.33337 5.10722 9.41737C4.86391 9.47991 4.63067 9.57651 4.41439 9.70431C4.12403 9.87591 3.87771 10.1222 3.38508 10.6149L1.33325 12.6667M8.66659 11H6.33325"
                    stroke="#9CA3AF"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  <path
                    opacity="0.4"
                    d="M3.33325 7.66671C3.33325 4.72118 5.72106 2.33337 8.66659 2.33337M8.66659 2.33337C11.6121 2.33337 13.9999 4.72118 13.9999 7.66671M8.66659 2.33337V1.33337"
                    stroke="#9CA3AF"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                </g>
                <defs>
                  <clipPath id="clip-servings">
                    <rect width="16" height="16" fill="white" />
                  </clipPath>
                </defs>
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
        className="fixed bottom-0 left-0 right-0 flex justify-center bg-white/80 backdrop-blur-xl border-t border-gray-100"
        style={{ paddingBottom: "max(12px, env(safe-area-inset-bottom))" }}
      >
        <div className="w-full max-w-lg px-5 pt-3">
          <a
            href={rechefHomeUrl}
            onClick={handleOpenInAppClick}
            className="flex w-full h-14 items-center justify-center rounded-full bg-[#FF4F63] px-4 text-base font-semibold text-white shadow-lg shadow-[#FF4F63]/20 transition-all hover:brightness-110 active:scale-[0.98]"
          >
            Open in Rechef
          </a>
          <p className="text-[11px] text-gray-400 text-center mt-2">
            Save recipes, build grocery lists, and cook smarter
          </p>
        </div>
      </div>
    </div>
  );
}
