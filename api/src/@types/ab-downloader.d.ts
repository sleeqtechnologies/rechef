declare module "ab-downloader" {
  export function igdl(url: string): Promise<Array<{ url?: string; thumbnail?: string }>>;
}
