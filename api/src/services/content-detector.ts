type ContentSource = "youtube" | "tiktok" | "instagram" | "website" | "image";

interface ContentInfo {
  source: ContentSource;
  url: string;
  videoId?: string;
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
