import { getSql } from "./db";
import { publicLyricsPayload } from "./lyrics-format";
import {
  EMPTY_SONG_TABS,
  parseTabsJson,
  songIdSchema,
  songInputSchema,
  songOrderSchema,
  songTabsSchema,
  songVisibilitySchema,
  type SongInput,
  type SongOrderInput,
  type SongRecord,
  type SongTabs,
  type SongVisibilityInput,
} from "./schemas";

type SongRow = {
  id: string;
  title: string;
  lyrics: string;
  starts_on: string;
  sort_order: number;
  hidden: boolean;
  tabs: unknown;
  created_at: Date | string;
  updated_at: Date | string;
};

export async function listSongs(): Promise<SongRecord[]> {
  const sql = getSql();
  const rows = (await sql`
    select id, title, lyrics, starts_on, sort_order, hidden, tabs, created_at, updated_at
    from songs
    order by sort_order asc, title asc
  `) as SongRow[];

  return rows.map(songRowToRecord);
}

export async function getSong(id: string): Promise<SongRecord | null> {
  const parsedId = songIdSchema.parse(id);
  const sql = getSql();
  const rows = (await sql`
    select id, title, lyrics, starts_on, sort_order, hidden, tabs, created_at, updated_at
    from songs
    where id = ${parsedId}
    limit 1
  `) as SongRow[];

  return rows[0] ? songRowToRecord(rows[0]) : null;
}

export async function createSong(input: SongInput): Promise<SongRecord> {
  const parsedInput = songInputSchema.parse(input);
  const sql = getSql();
  const tabsJson = JSON.stringify(parsedInput.tabs);
  const rows = (await sql`
    insert into songs (title, lyrics, starts_on, sort_order, hidden, tabs)
    values (
      ${parsedInput.title},
      ${parsedInput.lyrics},
      ${parsedInput.startsOn},
      ${parsedInput.sortOrder},
      ${parsedInput.hidden},
      ${tabsJson}::jsonb
    )
    returning id, title, lyrics, starts_on, sort_order, hidden, tabs, created_at, updated_at
  `) as SongRow[];

  return songRowToRecord(rows[0]);
}

export async function updateSong(id: string, input: SongInput): Promise<SongRecord | null> {
  const parsedId = songIdSchema.parse(id);
  const parsedInput = songInputSchema.parse(input);
  const sql = getSql();
  const tabsJson = JSON.stringify(parsedInput.tabs);
  const rows = (await sql`
    update songs
    set title = ${parsedInput.title},
        lyrics = ${parsedInput.lyrics},
        starts_on = ${parsedInput.startsOn},
        sort_order = ${parsedInput.sortOrder},
        hidden = ${parsedInput.hidden},
        tabs = ${tabsJson}::jsonb
    where id = ${parsedId}
    returning id, title, lyrics, starts_on, sort_order, hidden, tabs, created_at, updated_at
  `) as SongRow[];

  return rows[0] ? songRowToRecord(rows[0]) : null;
}

export async function deleteSong(id: string): Promise<boolean> {
  const parsedId = songIdSchema.parse(id);
  const sql = getSql();
  const rows = (await sql`
    delete from songs
    where id = ${parsedId}
    returning id
  `) as Array<{ id: string }>;

  return rows.length > 0;
}

export async function reorderSongs(input: SongOrderInput): Promise<SongRecord[]> {
  const { songIds } = songOrderSchema.parse(input);
  const sql = getSql();

  for (const [sortOrder, songId] of songIds.entries()) {
    await sql`
      update songs
      set sort_order = ${sortOrder}
      where id = ${songId}
    `;
  }

  return listSongs();
}

export async function updateSongVisibility(input: SongVisibilityInput): Promise<SongRecord[]> {
  const { songs } = songVisibilitySchema.parse(input);
  const sql = getSql();

  for (const song of songs) {
    await sql`
      update songs
      set hidden = ${song.hidden}
      where id = ${song.id}
    `;
  }

  return listSongs();
}

export async function getPublicLyricsPayload() {
  return publicLyricsPayload(await listSongs());
}

export function songFormDataToInput(formData: FormData): SongInput {
  return songInputSchema.parse({
    title: formData.get("title"),
    lyrics: formData.get("lyrics") ?? "",
    startsOn: formData.get("startsOn") ?? "",
    sortOrder: formData.get("sortOrder") ?? 0,
    hidden: formData.get("hidden") ?? "false",
    tabs: parseTabsJson(formData.get("tabs")),
  });
}

function songRowToRecord(row: SongRow): SongRecord {
  return {
    id: row.id,
    title: row.title,
    lyrics: row.lyrics,
    startsOn: row.starts_on,
    sortOrder: row.sort_order,
    hidden: Boolean(row.hidden),
    tabs: normalizeTabs(row.tabs),
    createdAt: toIsoString(row.created_at),
    updatedAt: toIsoString(row.updated_at),
  };
}

function normalizeTabs(value: unknown): SongTabs {
  if (value == null) {
    return EMPTY_SONG_TABS;
  }

  if (typeof value === "string") {
    return parseTabsJson(value);
  }

  const result = songTabsSchema.safeParse(value);

  return result.success ? result.data : EMPTY_SONG_TABS;
}

function toIsoString(value: Date | string): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}
