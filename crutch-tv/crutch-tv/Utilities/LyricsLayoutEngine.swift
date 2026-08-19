import CoreGraphics
import Foundation
import UIKit

enum LyricsLayoutEngine {
    struct Column: Equatable {
        let text: String
        let pageIndex: Int
    }

    struct ScreenLayout: Equatable {
        let fontSize: CGFloat
        let columns: [Column]
    }

    struct Metrics: Equatable {
        let usableWidth: CGFloat
        let usableHeight: CGFloat
        let columnSpacing: CGFloat
        let columnsPerScreen: Int
    }

    private static let minimumFontSize: CGFloat = 28
    private static let maximumFontSize: CGFloat = 120
    private static let columnPadding: CGFloat = 9
    private static let pageLabelOverhead: CGFloat = 28

    static func computeAllScreenLayouts(pages: [String], metrics: Metrics) -> [ScreenLayout] {
        guard !pages.isEmpty else {
            return [ScreenLayout(fontSize: minimumFontSize, columns: [Column(text: "", pageIndex: 0)])]
        }

        let columnWidth = columnWidth(
            usableWidth: metrics.usableWidth,
            columnSpacing: metrics.columnSpacing,
            columns: metrics.columnsPerScreen
        )
        var cache = HeightCache()

        if pages.count == 1 {
            return [singlePageLayout(
                page: pages[0],
                columnWidth: columnWidth,
                columnHeight: metrics.usableHeight,
                cache: &cache
            )]
        }

        if pages.count == 2 {
            return [twoPageLayout(
                pages: pages,
                columnWidth: columnWidth,
                columnHeight: metrics.usableHeight,
                cache: &cache
            )]
        }

        let screenCount = max(1, Int(ceil(Double(pages.count) / Double(metrics.columnsPerScreen))))
        return (0..<screenCount).map { screenIndex in
            let startPage = screenIndex * metrics.columnsPerScreen
            let endPage = min(startPage + metrics.columnsPerScreen, pages.count)
            let columns = (startPage..<endPage).map { pageIndex in
                Column(text: pages[pageIndex], pageIndex: pageIndex)
            }
            let fontSize = refinedMaximumFontSize(
                for: columns.map(\.text),
                columnWidth: columnWidth,
                columnHeight: metrics.usableHeight,
                showsPageLabel: true,
                cache: &cache
            )
            return ScreenLayout(fontSize: fontSize, columns: columns)
        }
    }

    static func columnsPerScreen(for pageCount: Int) -> Int {
        switch pageCount {
        case 0, 1, 2:
            return 2
        default:
            return 3
        }
    }

    static func columnWidth(usableWidth: CGFloat, columnSpacing: CGFloat, columns: Int) -> CGFloat {
        guard columns > 0 else {
            return usableWidth
        }

        let totalSpacing = columnSpacing * CGFloat(max(columns - 1, 0))
        return (usableWidth - totalSpacing) / CGFloat(columns)
    }

    private struct HeightCache {
        private var storage: [String: CGFloat] = [:]

        mutating func height(for text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
            let key = "\(fontSize)-\(width)-\(text.count)-\(text.hashValue)"
            if let cached = storage[key] {
                return cached
            }
            let value = measuredHeight(for: text, width: width, fontSize: fontSize)
            storage[key] = value
            return value
        }
    }

    private static func twoPageLayout(
        pages: [String],
        columnWidth: CGFloat,
        columnHeight: CGFloat,
        cache: inout HeightCache
    ) -> ScreenLayout {
        let columns = [
            Column(text: pages[0], pageIndex: 0),
            Column(text: pages[1], pageIndex: 1)
        ]
        let fontSize = refinedMaximumFontSize(
            for: pages,
            columnWidth: columnWidth,
            columnHeight: columnHeight,
            showsPageLabel: true,
            cache: &cache
        )
        return ScreenLayout(fontSize: fontSize, columns: columns)
    }

    private static func singlePageLayout(
        page: String,
        columnWidth: CGFloat,
        columnHeight: CGFloat,
        cache: inout HeightCache
    ) -> ScreenLayout {
        let splittableLines = splittableLineGroups(from: page)
        let textWidth = max(columnWidth - (columnPadding * 2), 1)
        let textAreaHeight = lyricsTextAreaHeight(columnHeight: columnHeight, showsPageLabel: false)
        let defaultSplit = defaultTwoColumnSplit(for: page)

        var low = Int(minimumFontSize)
        var high = Int(maximumFontSize)
        var bestFont = minimumFontSize

        while low <= high {
            let candidate = CGFloat((low + high) / 2)
            if splitFits(
                defaultSplit,
                fontSize: candidate,
                textWidth: textWidth,
                textAreaHeight: textAreaHeight,
                cache: &cache
            ) {
                bestFont = candidate
                low = Int(candidate) + 1
            } else {
                high = Int(candidate) - 1
            }
        }

        bestFont = refineFontSizeUpward(
            from: bestFont,
            texts: defaultSplit,
            textWidth: textWidth,
            textAreaHeight: textAreaHeight,
            cache: &cache
        )

        let bestSplit = optimalTwoColumnSplit(
            lines: splittableLines,
            fontSize: bestFont,
            textWidth: textWidth,
            textAreaHeight: textAreaHeight,
            cache: &cache
        ) ?? defaultSplit

        let columns = bestSplit.map { Column(text: $0, pageIndex: 0) }
        return ScreenLayout(fontSize: bestFont, columns: columns)
    }

    private static func refinedMaximumFontSize(
        for texts: [String],
        columnWidth: CGFloat,
        columnHeight: CGFloat,
        showsPageLabel: Bool,
        cache: inout HeightCache
    ) -> CGFloat {
        guard !texts.isEmpty else {
            return minimumFontSize
        }

        let textWidth = max(columnWidth - (columnPadding * 2), 1)
        let textAreaHeight = lyricsTextAreaHeight(columnHeight: columnHeight, showsPageLabel: showsPageLabel)

        var low = Int(minimumFontSize)
        var high = Int(maximumFontSize)
        var best = minimumFontSize

        while low <= high {
            let candidate = CGFloat((low + high) / 2)
            let fits = texts.allSatisfy {
                cache.height(for: $0, width: textWidth, fontSize: candidate) <= textAreaHeight
            }
            if fits {
                best = candidate
                low = Int(candidate) + 1
            } else {
                high = Int(candidate) - 1
            }
        }

        return refineFontSizeUpward(
            from: best,
            texts: texts,
            textWidth: textWidth,
            textAreaHeight: textAreaHeight,
            cache: &cache
        )
    }

    private static func refineFontSizeUpward(
        from fontSize: CGFloat,
        texts: [String],
        textWidth: CGFloat,
        textAreaHeight: CGFloat,
        cache: inout HeightCache
    ) -> CGFloat {
        var best = fontSize
        var candidate = fontSize + 0.5
        while candidate <= maximumFontSize {
            let fits = texts.allSatisfy {
                cache.height(for: $0, width: textWidth, fontSize: candidate) <= textAreaHeight
            }
            if fits {
                best = candidate
                candidate += 0.5
            } else {
                break
            }
        }
        return best
    }

    private static func splitFits(
        _ texts: [String],
        fontSize: CGFloat,
        textWidth: CGFloat,
        textAreaHeight: CGFloat,
        cache: inout HeightCache
    ) -> Bool {
        texts.allSatisfy {
            cache.height(for: $0, width: textWidth, fontSize: fontSize) <= textAreaHeight
        }
    }

    private static func optimalTwoColumnSplit(
        lines: [String],
        fontSize: CGFloat,
        textWidth: CGFloat,
        textAreaHeight: CGFloat,
        cache: inout HeightCache
    ) -> [String]? {
        guard lines.count > 1 else {
            let text = lines.first ?? ""
            let height = cache.height(for: text, width: textWidth, fontSize: fontSize)
            return height <= textAreaHeight ? [text, ""] : nil
        }

        var bestSplit: [String]?
        var bestLastSlack = CGFloat.greatestFiniteMagnitude

        for splitIndex in 1..<lines.count {
            let left = lines[0..<splitIndex].joined(separator: "\n")
            let right = lines[splitIndex...].joined(separator: "\n")
            let leftHeight = cache.height(for: left, width: textWidth, fontSize: fontSize)
            let rightHeight = cache.height(for: right, width: textWidth, fontSize: fontSize)

            guard leftHeight <= textAreaHeight, rightHeight <= textAreaHeight else {
                continue
            }

            let lastSlack = textAreaHeight - rightHeight
            if lastSlack < bestLastSlack {
                bestLastSlack = lastSlack
                bestSplit = [left, right]
            }
        }

        return bestSplit
    }

    private static func splittableLineGroups(from text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        guard lines.count <= 1 else {
            return lines
        }

        let words = text.split(whereSeparator: \.isWhitespace)
        guard words.count > 1 else {
            return lines.isEmpty ? [""] : lines
        }

        let midpoint = words.count / 2
        return [
            words[..<midpoint].joined(separator: " "),
            words[midpoint...].joined(separator: " ")
        ]
    }

    private static func defaultTwoColumnSplit(for text: String) -> [String] {
        let lines = splittableLineGroups(from: text)
        guard lines.count > 1 else {
            return [text, ""]
        }

        let midpoint = lines.count / 2
        return [
            lines[..<midpoint].joined(separator: "\n"),
            lines[midpoint...].joined(separator: "\n")
        ]
    }

    private static func lyricsTextAreaHeight(columnHeight: CGFloat, showsPageLabel: Bool) -> CGFloat {
        var overhead = columnPadding * 2
        if showsPageLabel {
            overhead += pageLabelOverhead
        }
        return max(columnHeight - overhead, 1)
    }

    private static func measuredHeight(for text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        guard !text.isEmpty else {
            return 0
        }

        let visible = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "~~", with: "")

        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        let rect = (visible as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(rect.height)
    }
}
