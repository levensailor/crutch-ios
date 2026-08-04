# Crutch iOS

Crutch is a SwiftUI performance lyrics app. It renders marker-defined lyrics pages from `lyrics.md`, supports Bluetooth page turners that appear as hardware keyboards, and now includes a Vercel-hosted lyrics manager for editing the canonical lyrics feed.

Author: Jeff Levensailor

## Marker Format

- `# Song Title` starts a song.
- `###` opens and closes the lyrics block for a song.
- `#####` on a line creates a page break.
- `**text**` highlights text in pink.
- `~~text~~` highlights text in green.

The iOS app renders each marker-defined page as a condensed, non-scrolling performance screen. Swipe left/right is available as a fallback if the Bluetooth page turner dies mid-performance. On the last page of a song, next advances to the first page of the next visible setlist song so you can pedal through an entire show. While a song is open, the title appears in the Dynamic Island (and Lock Screen Live Activity) and scrolls when it is too long to fit.

## Lyrics Manager

The Vercel app lives in `lyrics-manager/`. It provides:

- Public song CRUD: create, read, update, and delete songs by clicking a song name.
- A cacheable public feed for the iOS app at `/api/public/lyrics`.
- A live iPhone 16 Pro screen simulator on the edit page.
- Toolbar actions for highlight cues and automatic page-break insertion.
- A song-level "Starts on" field that renders under the iOS back button.
- An in-place editable song title and a Tabs panel with draggable note pills (A through G#m, major and minor) that are positioned per page on the simulator and rendered on the iOS lyrics screen.
- A song-level `hidden` flag so the iOS setlist can show/hide songs from the performance list.
- Long-press drag reordering on the iOS setlist, persisted through the existing `sort_order` column. New songs append at the end of the order and default to `hidden=false`.

Editing is intentionally public in this version. Anyone with the URL can change lyrics.

## Deployment

1. Create a Vercel project with `lyrics-manager/` as the project root.
2. Add a Neon Postgres store from the Vercel Marketplace.
3. Run `lyrics-manager/db/001_create_songs.sql` and later numbered migration files manually against the Neon database.
4. Ensure `DATABASE_URL` is configured in the Vercel project.
5. Deploy the Vercel project.
6. Set `LyricsPublicURL` in `crutch/crutch/Resources/AppConfig.plist` to the deployed public feed URL, for example `https://your-project.vercel.app/api/public/lyrics`.

## Public Assets

- Lyrics Manager: deploy URL from Vercel after setup.
- Public iOS feed: `https://your-project.vercel.app/api/public/lyrics`
- Login instructions: no login is required for this public-editing version.

## Local Notes

The bundled `crutch/crutch/Resources/lyrics.md` remains the final offline fallback. If the Vercel feed is unavailable, the app uses the last cached good feed, then bundled lyrics.
