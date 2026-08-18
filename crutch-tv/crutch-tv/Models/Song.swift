import Foundation

struct TabPlacement: Identifiable, Equatable {
    let id: String
    let note: String
    let x: Double
    let y: Double
}

struct TabPage: Equatable {
    let pageIndex: Int
    let notes: [TabPlacement]
}

struct SongTabs: Equatable {
    let version: Int
    let pages: [TabPage]

    static let empty = SongTabs(version: 1, pages: [])

    func placements(forPageIndex pageIndex: Int) -> [TabPlacement] {
        pages.first(where: { $0.pageIndex == pageIndex })?.notes ?? []
    }
}

struct Song: Identifiable, Hashable {
    let id: UUID
    let title: String
    let lyrics: String
    let startsOn: String?
    let tabs: SongTabs
    var isHidden: Bool

    init(
        id: UUID = UUID(),
        title: String,
        lyrics: String,
        startsOn: String? = nil,
        tabs: SongTabs = .empty,
        isHidden: Bool = false
    ) {
        self.id = id
        self.title = title
        self.lyrics = lyrics
        self.startsOn = startsOn
        self.tabs = tabs
        self.isHidden = isHidden
    }

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct SongLoader {
    static func loadBundledSongs() -> [Song] {
        guard let url = Bundle.main.url(forResource: "lyrics", withExtension: "md"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("Error: Could not load lyrics.md")
            return []
        }

        return parseMarkdown(content)
    }

    static func parseMarkdown(_ content: String) -> [Song] {
        var songs: [Song] = []
        let lines = content.components(separatedBy: .newlines)

        var currentTitle: String?
        var currentLyrics: [String] = []
        var inLyricsBlock = false

        for line in lines {
            if line.hasPrefix("# ") {
                if let title = currentTitle, !currentLyrics.isEmpty {
                    let lyrics = currentLyrics.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    let processedLyrics = lyrics.replacingOccurrences(of: "\\n", with: "\n")
                    songs.append(Song(title: title, lyrics: processedLyrics))
                }

                currentTitle = String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentLyrics = []
                inLyricsBlock = false
            } else if line.trimmingCharacters(in: .whitespaces) == "###" {
                if !inLyricsBlock {
                    inLyricsBlock = true
                } else {
                    if let title = currentTitle, !currentLyrics.isEmpty {
                        let lyrics = currentLyrics.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                        let processedLyrics = lyrics.replacingOccurrences(of: "\\n", with: "\n")
                        songs.append(Song(title: title, lyrics: processedLyrics))
                    }
                    currentTitle = nil
                    currentLyrics = []
                    inLyricsBlock = false
                }
            } else if inLyricsBlock {
                currentLyrics.append(line)
            }
        }

        if let title = currentTitle, !currentLyrics.isEmpty {
            let lyrics = currentLyrics.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let processedLyrics = lyrics.replacingOccurrences(of: "\\n", with: "\n")
            songs.append(Song(title: title, lyrics: processedLyrics))
        }

        return songs
    }
}
