# Changelog

## 2026-04-27 07:18 EDT

- Add a Vercel-hosted lyrics manager backed by Neon Postgres.
- Add a public cached lyrics feed for the iOS app.
- Add remote lyrics caching with bundled fallback in the iOS app.
- Add swipe page-turn fallback for performances.
- Add an iPhone 16 Pro lyrics screen simulator and marker-writing guide.

## 2026-04-27 12:21 EDT

- Add a starts-on note field to lyrics manager songs and render it under the iOS back button.

## 2026-05-07 13:20 EDT

- Add page-specific draggable tab pills to the lyrics manager simulator and the iOS lyrics screen.
- Make the song title editable in place and remove the separate song name, sort order, and starts-on text boxes.

## 2026-05-07 14:20 EDT

- Move the tab note pills into a palette above the iPhone simulator so they can be dragged onto the screen, repositioned, duplicated, and removed by dragging off-screen.
- Shrink tab pills on the simulator and the iOS lyrics screen so they no longer overlap performance text, and render only placed instances on iOS.

## 2026-08-04 11:10 EDT

- Add a song-level hidden flag (default false) and an iOS show/hide list mode that saves visibility back to the lyrics manager.

## 2026-08-04 11:25 EDT

- Add long-press drag reordering on the iOS setlist (0.5s hold), persisted via `sort_order`.
- Ensure newly created songs append with the next `sort_order` and always start as `hidden=false`.

## 2026-08-04 11:30 EDT

- Advance from the last lyrics page of a song to the first page of the next setlist song via page turner or swipe.

## 2026-08-04 11:55 EDT

- Remove Dynamic Island / Live Activity song-title display and the CrutchWidgets extension.

## 2026-08-18 11:45 EDT

- Add a standalone Apple TV (tvOS 18) lyrics app under `crutch-tv/` that reads the public lyrics feed and renders pages as widescreen columns navigable with the Siri Remote.

## 2026-08-19 13:59 EDT

- Adapt Apple TV lyrics column widths by page count: one full-width column for single-page songs, two equal columns for two-page songs, and three columns per screen with pagination for longer songs.

## 2026-08-19 14:29 EDT

- Add the Croatoa pink yin-yang artwork as the Apple TV app icon via Brand Assets image stacks.
