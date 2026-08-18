import Foundation

enum LyricsPaginator {
    static func splitByPageMarkers(_ lyrics: String) -> [String] {
        let text = lyrics.replacingOccurrences(of: "\\n", with: "\n")

        if text.isEmpty {
            return [""]
        }

        let lines = text.components(separatedBy: .newlines)
        var pages: [String] = []
        var currentPage: [String] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine == "#####" || trimmedLine.hasPrefix("#####") || trimmedLine.hasSuffix("#####") {
                if !currentPage.isEmpty {
                    pages.append(currentPage.joined(separator: "\n"))
                    currentPage = []
                }
                continue
            }

            currentPage.append(line)
        }

        if !currentPage.isEmpty {
            pages.append(currentPage.joined(separator: "\n"))
        }

        if pages.isEmpty {
            pages.append(text)
        }

        return pages
    }
}
