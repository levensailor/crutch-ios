import { describe, expect, it } from "vitest";
import {
  autoAddPageMarkers,
  checksumMarkdown,
  publicLyricsPayload,
  songsToMarkdown,
  splitByPageMarkers,
} from "./lyrics-format";
import type { SongRecord } from "./schemas";

describe("lyrics format", () => {
  it("serializes songs to the markdown contract used by the iOS app", () => {
    expect(songsToMarkdown([song({ title: "Start a Fire", lyrics: "line one\nline two" })])).toBe(
      "# Start a Fire\n###\nline one\nline two\n###"
    );
  });

  it("splits pages by the same ##### markers as the iOS app", () => {
    expect(splitByPageMarkers("first\n#####\nsecond\nending #####\nthird")).toEqual([
      "first",
      "second",
      "third",
    ]);
  });

  it("auto-adds page markers without preserving old markers", () => {
    expect(
      autoAddPageMarkers("one\ntwo\n#####\nthree\nfour", {
        maxLines: 2,
        maxCharacters: 200,
      })
    ).toBe("one\ntwo\n#####\nthree\nfour");
  });

  it("auto-adds page markers when a page gets too many characters", () => {
    expect(
      autoAddPageMarkers("short\nthis line is too long for the configured page", {
        maxLines: 10,
        maxCharacters: 20,
      })
    ).toBe("short\n#####\nthis line is too long for the configured page");
  });

  it("builds a public payload with a checksum over the exact markdown", () => {
    const songs = [song({ title: "Checksum Song", lyrics: "lyric" })];
    const payload = publicLyricsPayload(songs);

    expect(payload.markdown).toBe("# Checksum Song\n###\nlyric\n###");
    expect(payload.checksum).toBe(checksumMarkdown(payload.markdown));
    expect(payload.version).toBeGreaterThan(0);
  });
});

function song(overrides: Partial<SongRecord>): SongRecord {
  return {
    id: "00000000-0000-4000-8000-000000000000",
    title: "Song",
    lyrics: "",
    sortOrder: 0,
    createdAt: "2026-04-27T00:00:00.000Z",
    updatedAt: "2026-04-27T00:00:00.000Z",
    ...overrides,
  };
}
