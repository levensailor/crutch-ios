import { getSql } from "./db";
import { publicLyricsPayload } from "./lyrics-format";
import { songIdSchema, songInputSchema, type SongInput, type SongRecord } from "./schemas";

type SongRow = {
  id: string;
  title: string;
  lyrics: string;
  sort_order: number;
  created_at: Date | string;
  updated_at: Date | string;
};

export async function listSongs(): Promise<SongRecord[]> {
  const sql = getSql();
  const rows = await sql<SongRow[]>`
    select id, title, lyrics, sort_order, created_at, updated_at
    from songs
    order by sort_order asc, title asc
  `;

  return rows.map(songRowToRecord);
}

export async function getSong(id: string): Promise<SongRecord | null> {
  const parsedId = songIdSchema.parse(id);
  const sql = getSql();
  const rows = await sql<SongRow[]>`
    select id, title, lyrics, sort_order, created_at, updated_at
    from songs
    where id = ${parsedId}
    limit 1
  `;

  return rows[0] ? songRowToRecord(rows[0]) : null;
}

export async function createSong(input: SongInput): Promise<SongRecord> {
  const parsedInput = songInputSchema.parse(input);
  const sql = getSql();
  const rows = await sql<SongRow[]>`
    insert into songs (title, lyrics, sort_order)
    values (${parsedInput.title}, ${parsedInput.lyrics}, ${parsedInput.sortOrder})
    returning id, title, lyrics, sort_order, created_at, updated_at
  `;

  return songRowToRecord(rows[0]);
}

export async function updateSong(id: string, input: SongInput): Promise<SongRecord | null> {
  const parsedId = songIdSchema.parse(id);
  const parsedInput = songInputSchema.parse(input);
  const sql = getSql();
  const rows = await sql<SongRow[]>`
    update songs
    set title = ${parsedInput.title},
        lyrics = ${parsedInput.lyrics},
        sort_order = ${parsedInput.sortOrder}
    where id = ${parsedId}
    returning id, title, lyrics, sort_order, created_at, updated_at
  `;

  return rows[0] ? songRowToRecord(rows[0]) : null;
}

export async function deleteSong(id: string): Promise<boolean> {
  const parsedId = songIdSchema.parse(id);
  const sql = getSql();
  const rows = await sql<{ id: string }[]>`
    delete from songs
    where id = ${parsedId}
    returning id
  `;

  return rows.length > 0;
}

export async function getPublicLyricsPayload() {
  return publicLyricsPayload(await listSongs());
}

export function songFormDataToInput(formData: FormData): SongInput {
  return songInputSchema.parse({
    title: formData.get("title"),
    lyrics: formData.get("lyrics") ?? "",
    sortOrder: formData.get("sortOrder") ?? 0,
  });
}

function songRowToRecord(row: SongRow): SongRecord {
  return {
    id: row.id,
    title: row.title,
    lyrics: row.lyrics,
    sortOrder: row.sort_order,
    createdAt: toIsoString(row.created_at),
    updatedAt: toIsoString(row.updated_at),
  };
}

function toIsoString(value: Date | string): string {
  return value instanceof Date ? value.toISOString() : new Date(value).toISOString();
}
