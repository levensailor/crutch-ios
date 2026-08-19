# Crutch TV

Apple TV (tvOS 18) setlist and lyrics viewer for the Crutch public lyrics feed.

## Open and run

1. Open `crutch-tv/crutch-tv.xcodeproj` in Xcode (or open the `crutch-tv` folder).
2. Select the **crutch-tv** scheme.
3. Choose a destination: a physical Apple TV or **Apple TV 4K** simulator.
4. Signing uses team `HU4EE3MB4T` with Automatic signing (same as the iOS app).
5. Press **Run**.

The app loads songs from `https://crutch-ios.vercel.app/api/public/lyrics`. If the network is unavailable, it uses the last cached feed, then the bundled `lyrics.md`.

## Remote navigation

- **Songs list:** clickpad / arrows to move, Select to open a song. Use Search (Siri Remote voice or text) to filter titles.
- **Lyrics:** pages render as **2 or 3 equal-width columns** depending on page count (1 page spreads across two larger-font columns, 2 pages = one page per column, 3+ = three columns per screen with pagination). Swipe or scroll the clickpad left/right to paginate when there are more than three pages. Menu returns to the setlist.

## Hidden songs

Songs marked `hidden` in the lyrics manager are omitted from the TV setlist.
