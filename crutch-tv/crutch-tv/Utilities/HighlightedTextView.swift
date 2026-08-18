import SwiftUI

enum LyricsHighlight {
    static func attributedString(from text: String, fontSize: CGFloat, weight: Font.Weight = .bold) -> AttributedString {
        let lines = text.components(separatedBy: .newlines)
        var result = AttributedString()

        for (lineIndex, line) in lines.enumerated() {
            if lineIndex > 0 {
                result.append(AttributedString("\n"))
            }
            result.append(processLine(line, fontSize: fontSize, weight: weight))
        }

        return result
    }

    private static func processLine(_ line: String, fontSize: CGFloat, weight: Font.Weight) -> AttributedString {
        enum MarkerKind {
            case pink
            case green
        }

        struct Marker {
            let open: Int
            let close: Int
            let kind: MarkerKind
        }

        var markers: [Marker] = []
        let nsLine = line as NSString

        var searchIndex = 0
        while searchIndex < nsLine.length {
            let openRange = nsLine.range(of: "**", options: [], range: NSRange(location: searchIndex, length: nsLine.length - searchIndex))
            guard openRange.location != NSNotFound else { break }
            let afterOpen = openRange.location + openRange.length
            let closeRange = nsLine.range(of: "**", options: [], range: NSRange(location: afterOpen, length: nsLine.length - afterOpen))
            guard closeRange.location != NSNotFound else { break }
            markers.append(Marker(open: openRange.location, close: closeRange.location, kind: .pink))
            searchIndex = closeRange.location + closeRange.length
        }

        searchIndex = 0
        while searchIndex < nsLine.length {
            let openRange = nsLine.range(of: "~~", options: [], range: NSRange(location: searchIndex, length: nsLine.length - searchIndex))
            guard openRange.location != NSNotFound else { break }
            let afterOpen = openRange.location + openRange.length
            let closeRange = nsLine.range(of: "~~", options: [], range: NSRange(location: afterOpen, length: nsLine.length - afterOpen))
            guard closeRange.location != NSNotFound else { break }
            markers.append(Marker(open: openRange.location, close: closeRange.location, kind: .green))
            searchIndex = closeRange.location + closeRange.length
        }

        markers.sort { $0.open < $1.open }

        var output = AttributedString()
        var cursor = 0

        for marker in markers {
            if marker.open < cursor {
                continue
            }

            if marker.open > cursor {
                let plain = nsLine.substring(with: NSRange(location: cursor, length: marker.open - cursor))
                output.append(styled(plain, fontSize: fontSize, weight: weight, background: nil))
            }

            let contentStart = marker.open + 2
            let contentLength = max(marker.close - contentStart, 0)
            if contentLength > 0 {
                let content = nsLine.substring(with: NSRange(location: contentStart, length: contentLength))
                let background: Color = marker.kind == .pink
                    ? Color.pink.opacity(0.35)
                    : Color.green.opacity(0.35)
                output.append(styled(content, fontSize: fontSize, weight: weight, background: background))
            }

            cursor = marker.close + 2
        }

        if cursor < nsLine.length {
            let plain = nsLine.substring(from: cursor)
            output.append(styled(plain, fontSize: fontSize, weight: weight, background: nil))
        }

        if markers.isEmpty {
            return styled(line, fontSize: fontSize, weight: weight, background: nil)
        }

        return output
    }

    private static func styled(
        _ text: String,
        fontSize: CGFloat,
        weight: Font.Weight,
        background: Color?
    ) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.font = .system(size: fontSize, weight: weight)
        attributed.foregroundColor = .primary
        if let background {
            attributed.backgroundColor = background
        }
        return attributed
    }
}

struct HighlightedLyricsText: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        Text(LyricsHighlight.attributedString(from: text, fontSize: fontSize))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
