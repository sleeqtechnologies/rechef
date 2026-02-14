type ContentSource = "youtube" | "tiktok" | "instagram" | "facebook" | "website" | "image";

interface ContentInfo {
  source: ContentSource;
  url: string;
  videoId?: string;
  isShort?: boolean;
}

function detectContentSource(url: string): ContentInfo {
  const normalizedUrl = url.toLowerCase().trim();

  if (
    normalizedUrl.includes("youtube.com") ||
    normalizedUrl.includes("youtu.be")
  ) {
    return {
      source: "youtube",
      url,
      videoId: extractYouTubeVideoId(url),
      isShort: normalizedUrl.includes("youtube.com/shorts/"),
    };
  }

  if (normalizedUrl.includes("tiktok.com")) {
    return {
      source: "tiktok",
      url,
      videoId: extractTikTokVideoId(url),
    };
  }

  if (
    (normalizedUrl.includes("instagram.com") ||
      normalizedUrl.includes("www.instagram.com")) &&
    (normalizedUrl.includes("/p/") ||
      normalizedUrl.includes("/reel/") ||
      normalizedUrl.includes("/reels/") ||
      normalizedUrl.includes("/tv/"))
  ) {
    return {
      source: "instagram",
      url,
    };
  }

  if (
    normalizedUrl.includes("fb.watch/") ||
    ((normalizedUrl.includes("facebook.com") ||
      normalizedUrl.includes("www.facebook.com") ||
      normalizedUrl.includes("m.facebook.com")) &&
      (normalizedUrl.includes("/watch") ||
        normalizedUrl.includes("/reel/") ||
        normalizedUrl.includes("/reels/") ||
        normalizedUrl.includes("/videos/") ||
        normalizedUrl.includes("/posts/") ||
        normalizedUrl.includes("/share/v/") ||
        normalizedUrl.includes("/share/r/")))
  ) {
    return {
      source: "facebook",
      url,
    };
  }

  if (/\.(jpg|jpeg|png|gif|webp|bmp)(\?.*)?$/i.test(normalizedUrl)) {
    return {
      source: "image",
      url,
    };
  }

  return {
    source: "website",
    url,
  };
}

function extractYouTubeVideoId(url: string): string | undefined {
  const patterns = [
    /(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|youtube\.com\/v\/)([^&\n?#]+)/,
    /youtube\.com\/shorts\/([^&\n?#]+)/,
  ];

  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) return match[1];
  }

  return undefined;
}

function extractTikTokVideoId(url: string): string | undefined {
  const patterns = [
    /tiktok\.com\/@[^/]+\/video\/(\d+)/,
    /tiktok\.com\/t\/([A-Za-z0-9]+)/,
    /vm\.tiktok\.com\/([A-Za-z0-9]+)/,
  ];

  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) return match[1];
  }

  return undefined;
}

export {
  detectContentSource,
  extractYouTubeVideoId,
  extractTikTokVideoId,
  ContentSource,
  ContentInfo,
};
