## Learned User Preferences
- Keep the iPhone 16 Pro web simulator visually aligned with the live iOS lyrics screen, including usable line count, padding, and overlaid page counter behavior.
- After code changes, commit and push the relevant changes to `main`; avoid SSH pushes.

## Learned Workspace Facts
- The workspace contains a SwiftUI iOS app under `crutch/` and a Next.js Vercel lyrics manager under `lyrics-manager/`.
- Lyrics use a stable marker contract: `# Song Title`, `###` lyrics blocks, `#####` page breaks, `**text**` pink highlights, and `~~text~~` green highlights.
- The iOS app loads remote lyrics through `LyricsRepository`, falling back to the last cached feed and then bundled `crutch/crutch/Resources/lyrics.md`.
- Bluetooth page-turner support is handled as hardware keyboard arrow-key input through UIKit key commands, with SwiftUI swipe gestures as the fallback.
- `lyrics-manager/` uses Next.js with Neon Postgres and exposes public song CRUD plus the cached `/api/public/lyrics` feed; editing is intentionally public.
- SQL changes for the lyrics manager live under `lyrics-manager/db/` and are intended to be run manually against Neon.
- The web simulator lives in the lyrics editor and targets iPhone 16 Pro layout; page count should be overlaid and padding should match iOS `.padding()`.
- The iOS `LyricsPublicURL` config should point to `https://crutch-ios.vercel.app/api/public/lyrics`; the site root is the manager UI, not the app feed.
- The lyrics manager supports drag-and-drop song ordering through `sort_order`, which controls the public feed order consumed by iOS.
- The lyrics editor uses toolbar actions that preserve the marker format behind the scenes and can auto-insert `#####` page breaks.
