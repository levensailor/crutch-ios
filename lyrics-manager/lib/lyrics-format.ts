import { createHash } from "crypto";
import type { SongRecord } from "./schemas";
export { renderInlineMarkers, splitByPageMarkers } from "./lyrics-markers";

export type PublicLyricsPayload = {
  version: number;
  updatedAt: string;
  checksum: string;
  markdown: string;
};

export type ParsedLyricsPage = {
  raw: string;
  html: string;
};

export function songsToMarkdown(songs: SongRecord[]): string {
  return songs
    .map((song) => {
      const lyrics = song.lyrics.trim();
      return `# ${song.title}\n###\n${lyrics}\n###`;
    })
    .join("\n\n");
}

export function checksumMarkdown(markdown: string): string {
  return createHash("sha256").update(markdown, "utf8").digest("hex");
}

export function publicLyricsPayload(songs: SongRecord[]): PublicLyricsPayload {
  const markdown = songsToMarkdown(songs);
  const updatedAt =
    songs
      .map((song) => song.updatedAt)
      .sort()
      .at(-1) ?? new Date(0).toISOString();
  const version = Math.max(1, Math.floor(new Date(updatedAt).getTime() / 1000));

  return {
    version,
    updatedAt,
    checksum: checksumMarkdown(markdown),
    markdown,
  };
}

