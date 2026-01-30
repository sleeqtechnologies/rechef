import { z } from "zod";

const parseContentSchema = z
  .object({
    url: z.string().url().optional(),
    imageBase64: z.string().optional(),
  })
  .refine((data) => data.url || data.imageBase64, {
    message: "Either url or imageBase64 must be provided",
  });

type ParseContentSchema = z.infer<typeof parseContentSchema>;

export {
  parseContentSchema,
  ParseContentSchema,
};
