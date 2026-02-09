import winstonDevConsole from "@epegzz/winston-dev-console";
import { createLogger, format, transports } from "winston";

import { env } from "./env_config";


let logger = createLogger({
  level: "silly",
  format: format.json(),
  defaultMeta: { service: "rechef" },
  transports: [
    new transports.Console({
      format: format.json(),
    }),
  ],
});

if (env.isDevelopment) {
  logger = winstonDevConsole.init(logger);
  logger.add(
    winstonDevConsole.transport({
      showTimestamps: true,
      addLineSeparation: true,
    }),
  );
}

export { logger };
