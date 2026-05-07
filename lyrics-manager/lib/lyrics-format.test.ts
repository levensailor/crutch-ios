import { describe, expect, it } from "vitest";
import {
  autoAddPageMarkers,
  checksumMarkdown,
  publicLyricsPayload,
  songsToMarkdown,
  splitByPageMarkers,
} from "./lyrics-format";
import { EMPTY_SONG_TABS, type SongRecord, type SongTabs } from "./schemas";

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
    const songs = [song({ title: "Checksum Song", lyrics: "lyric", startsOn: "Bm" })];
    const payload = publicLyricsPayload(songs);

    expect(payload.markdown).toBe("# Checksum Song\n###\nlyric\n###");
    expect(payload.checksum).toBe(checksumMarkdown(payload.markdown));
    expect(payload.songs[0].startsOn).toBe("Bm");
    expect(payload.version).toBeGreaterThan(0);
  });

  it("forwards page-specific tab placements through the public payload", () => {
    const tabs: SongTabs = {
      version: 1,
      pages: [
        {
          pageIndex: 0,
          notes: [
            { note: "A", x: 0.1, y: 0.2 },
            { note: "Bm", x: 0.5, y: 0.75 },
          ],
        },
      ],
    };
    const payload = publicLyricsPayload([song({ tabs })]);

    expect(payload.songs[0].tabs).toEqual(tabs);
  });

  it("defaults missing tabs to an empty payload", () => {
    const payload = publicLyricsPayload([song({})]);

    expect(payload.songs[0].tabs).toEqual(EMPTY_SONG_TABS);
  });
});

function song(overrides: Partial<SongRecord>): SongRecord {
  return {
    id: "00000000-0000-4000-8000-000000000000",
    title: "Song",
    lyrics: "",
    startsOn: "",
    sortOrder: 0,
    tabs: EMPTY_SONG_TABS,
    createdAt: "2026-04-27T00:00:00.000Z",
    updatedAt: "2026-04-27T00:00:00.000Z",
    ...overrides,
  };
}
