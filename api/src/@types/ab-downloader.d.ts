declare module "ab-downloader" {
  export function igdl(
    url: string,
  ): Promise<Array<{ url?: string; thumbnail?: string }>>;

  export function fbdown(
    url: string,
  ): Promise<{ Normal_video?: string; HD?: string }>;
}
