import { z } from "zod";

export const TAB_NOTES = [
  "A",
  "A#",
  "B",
  "C",
  "C#",
  "D",
  "D#",
  "E",
  "F",
  "F#",
  "G",
  "G#",
  "Am",
  "A#m",
  "Bm",
  "Cm",
  "C#m",
  "Dm",
  "D#m",
  "Em",
  "Fm",
  "F#m",
  "Gm",
  "G#m",
] as const;

export type TabNote = (typeof TAB_NOTES)[number];

export const tabNoteSchema = z.enum(TAB_NOTES);

export const tabPlacementSchema = z.object({
  id: z.string().min(1).optional(),
  note: tabNoteSchema,
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
});

export const tabPageSchema = z.object({
  pageIndex: z.number().int().min(0),
  notes: z.array(tabPlacementSchema).default([]),
});

export const songTabsSchema = z
  .object({
    version: z.literal(1).default(1),
    pages: z.array(tabPageSchema).default([]),
  })
  .default({ version: 1, pages: [] });

export const songIdSchema = z.string().uuid();

export const songInputSchema = z.object({
  title: z.string().trim().min(1, "Song title is required."),
  lyrics: z.string().transform((value) => value.replaceAll("\r\n", "\n")),
  startsOn: z.string().trim().default(""),
  sortOrder: z.coerce.number().int().min(0).default(0),
  tabs: songTabsSchema,
});

export const songRecordSchema = songInputSchema.extend({
  id: songIdSchema,
  createdAt: z.string(),
  updatedAt: z.string(),
});

export const songOrderSchema = z.object({
  songIds: z.array(songIdSchema).min(1, "At least one song id is required."),
});

export type TabPlacement = z.infer<typeof tabPlacementSchema>;
export type TabPage = z.infer<typeof tabPageSchema>;
export type SongTabs = z.infer<typeof songTabsSchema>;
export type SongInput = z.infer<typeof songInputSchema>;
export type SongRecord = z.infer<typeof songRecordSchema>;
export type SongOrderInput = z.infer<typeof songOrderSchema>;

export const EMPTY_SONG_TABS: SongTabs = { version: 1, pages: [] };

export function parseTabsJson(value: unknown): SongTabs {
  if (value == null) {
    return EMPTY_SONG_TABS;
  }

  let candidate: unknown = value;

  if (typeof value === "string") {
    try {
      candidate = JSON.parse(value);
    } catch {
      return EMPTY_SONG_TABS;
    }
  }

  const result = songTabsSchema.safeParse(candidate);

  return result.success ? result.data : EMPTY_SONG_TABS;
}
