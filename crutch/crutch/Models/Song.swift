import Foundation

struct Song: Identifiable {
    let id: UUID
    let title: String
    let lyrics: String
    let startsOn: String?
    
    init(id: UUID = UUID(), title: String, lyrics: String, startsOn: String? = nil) {
        self.id = id
        self.title = title
        self.lyrics = lyrics
        self.startsOn = startsOn
    }
}

struct SongLoader {
    static func loadSongs() -> [Song] {
        return loadBundledSongs()
    }
    
    static func loadBundledSongs() -> [Song] {
        guard let url = Bundle.main.url(forResource: "lyrics", withExtension: "md"),
              let content = try? String(contentsOf: url) else {
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
                // Save previous song if exists
                if let title = currentTitle, !currentLyrics.isEmpty {
                    let lyrics = currentLyrics.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    let processedLyrics = lyrics.replacingOccurrences(of: "\\n", with: "\n")
                    songs.append(Song(title: title, lyrics: processedLyrics))
                }
                
                // Start new song
                currentTitle = String(line.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentLyrics = []
                inLyricsBlock = false
            } else if line.trimmingCharacters(in: .whitespaces) == "###" {
                if !inLyricsBlock {
                    // Start of lyrics block
                    inLyricsBlock = true
                } else {
                    // End of lyrics block - save song
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
                // Collect lyrics lines
                currentLyrics.append(line)
            }
        }
        
        // Save last song if exists
        if let title = currentTitle, !currentLyrics.isEmpty {
            let lyrics = currentLyrics.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let processedLyrics = lyrics.replacingOccurrences(of: "\\n", with: "\n")
            songs.append(Song(title: title, lyrics: processedLyrics))
        }
        
        return songs
    }
}


