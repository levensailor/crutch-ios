import { z } from "zod";

export const songIdSchema = z.string().uuid();

export const songInputSchema = z.object({
  title: z.string().trim().min(1, "Song title is required."),
  lyrics: z.string().transform((value) => value.replaceAll("\r\n", "\n")),
  sortOrder: z.coerce.number().int().min(0).default(0),
});

export const songRecordSchema = songInputSchema.extend({
  id: songIdSchema,
  createdAt: z.string(),
  updatedAt: z.string(),
});

export const songOrderSchema = z.object({
  songIds: z.array(songIdSchema).min(1, "At least one song id is required."),
});

export type SongInput = z.infer<typeof songInputSchema>;
export type SongRecord = z.infer<typeof songRecordSchema>;
export type SongOrderInput = z.infer<typeof songOrderSchema>;
