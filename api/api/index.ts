import type { Request, Response } from "express";

let app: typeof import("../app").default | null = null;

async function loadApp() {
  if (app) return app;
  const m = await import("../app");
  app = m.default;
  return app;
}

function waitForResponse(res: Response): Promise<void> {
  return new Promise((resolve) => {
    res.on("finish", () => resolve());
    res.on("close", () => resolve());
  });
}

export default async function handler(req: Request, res: Response) {
  try {
    const expressApp = await loadApp();
    expressApp(req, res);
    await waitForResponse(res);
  } catch (err) {
    console.error("Serverless function error:", err);
    if (!res.headersSent) {
      res.status(503).setHeader("Content-Type", "application/json");
      res.end(
        JSON.stringify({
          error: "Startup failed",
          message: err instanceof Error ? err.message : String(err),
        })
      );
    }
  }
}
