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
