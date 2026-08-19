import SwiftUI
import UIKit

struct LyricsColumnsView: View {
    let song: Song

    private let minimumFontSize: CGFloat = 28
    private let maximumFontSize: CGFloat = 120
    private let columnPadding: CGFloat = 9
    private let pageLabelOverhead: CGFloat = 28

    @State private var pages: [String] = []
    @State private var selectedScreen = 0

    /// Single-page songs spread across two columns; 2-page songs use two; 3+ paginate in threes.
    private var columnsPerScreen: Int {
        switch pages.count {
        case 0, 1:
            return 2
        case 2:
            return 2
        default:
            return 3
        }
    }

    private var isSinglePageSpread: Bool {
        pages.count == 1
    }

    private var isTwoPageLayout: Bool {
        pages.count == 2
    }

    private var screenCount: Int {
        if isSinglePageSpread {
            return 1
        }
        return max(1, Int(ceil(Double(max(pages.count, 1)) / Double(columnsPerScreen))))
    }

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 24
            let verticalPadding: CGFloat = 18
            let columnSpacing: CGFloat = 14
            let headerHeight: CGFloat = 72
            let usableWidth = geometry.size.width - (horizontalPadding * 2)
            let usableHeight = geometry.size.height - verticalPadding * 2 - headerHeight
            let columnWidth = columnWidth(
                usableWidth: usableWidth,
                columnSpacing: columnSpacing,
                columns: columnsPerScreen
            )

            VStack(alignment: .leading, spacing: 16) {
                header

                TabView(selection: $selectedScreen) {
                    ForEach(0..<screenCount, id: \.self) { screenIndex in
                        screenRow(
                            screenIndex: screenIndex,
                            columnWidth: columnWidth,
                            columnHeight: usableHeight,
                            columnSpacing: columnSpacing
                        )
                        .tag(screenIndex)
                        .focusable(true)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: screenCount > 1 ? .automatic : .never))
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color.black)
        .foregroundStyle(.white)
        .onAppear {
            pages = LyricsPaginator.splitByPageMarkers(song.lyrics)
            selectedScreen = 0
        }
    }

    @ViewBuilder
    private func screenRow(
        screenIndex: Int,
        columnWidth: CGFloat,
        columnHeight: CGFloat,
        columnSpacing: CGFloat
    ) -> some View {
        let layout = screenLayout(
            screenIndex: screenIndex,
            columnWidth: columnWidth,
            columnHeight: columnHeight
        )

        HStack(alignment: .top, spacing: columnSpacing) {
            ForEach(Array(layout.columns.enumerated()), id: \.offset) { _, column in
                pageColumn(
                    text: column.text,
                    pageIndex: column.pageIndex,
                    width: columnWidth,
                    height: columnHeight,
                    fontSize: layout.fontSize
                )
            }

            if layout.columns.count < columnsPerScreen {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func screenLayout(
        screenIndex: Int,
        columnWidth: CGFloat,
        columnHeight: CGFloat
    ) -> (fontSize: CGFloat, columns: [(text: String, pageIndex: Int)]) {
        if isSinglePageSpread {
            return singlePageLayout(columnWidth: columnWidth, columnHeight: columnHeight)
        }

        if isTwoPageLayout {
            return twoPageLayout(columnWidth: columnWidth, columnHeight: columnHeight)
        }

        let startPage = screenIndex * columnsPerScreen
        let endPage = min(startPage + columnsPerScreen, pages.count)
        let columns = (startPage..<endPage).map { pageIndex in
            (text: pages[pageIndex], pageIndex: pageIndex)
        }
        let fontSize = refinedMaximumFontSize(
            for: columns.map(\.text),
            columnWidth: columnWidth,
            columnHeight: columnHeight,
            showsPageLabel: pages.count > 1
        )
        return (fontSize, columns)
    }

    private func twoPageLayout(
        columnWidth: CGFloat,
        columnHeight: CGFloat
    ) -> (fontSize: CGFloat, columns: [(text: String, pageIndex: Int)]) {
        let columns = [
            (text: pages[0], pageIndex: 0),
            (text: pages[1], pageIndex: 1)
        ]
        let fontSize = refinedMaximumFontSize(
            for: [pages[0], pages[1]],
            columnWidth: columnWidth,
            columnHeight: columnHeight,
            showsPageLabel: true
        )
        return (fontSize, columns)
    }

    private func singlePageLayout(
        columnWidth: CGFloat,
        columnHeight: CGFloat
    ) -> (fontSize: CGFloat, columns: [(text: String, pageIndex: Int)]) {
        let splittableLines = splittableLineGroups(from: pages[0])
        let textWidth = max(columnWidth - (columnPadding * 2), 1)
        let textAreaHeight = lyricsTextAreaHeight(columnHeight: columnHeight, showsPageLabel: false)

        var bestFont = minimumFontSize
        var bestSplit = defaultTwoColumnSplit(for: pages[0])

        var low = Int(minimumFontSize)
        var high = Int(maximumFontSize)
        while low <= high {
            let candidate = CGFloat((low + high) / 2)
            if let split = optimalTwoColumnSplit(
                lines: splittableLines,
                fontSize: candidate,
                textWidth: textWidth,
                textAreaHeight: textAreaHeight
            ) {
                bestFont = candidate
                bestSplit = split
                low = Int(candidate) + 1
            } else {
                high = Int(candidate) - 1
            }
        }

        bestFont = refineFontSizeUpward(
            from: bestFont,
            texts: bestSplit,
            textWidth: textWidth,
            textAreaHeight: textAreaHeight
        )

        return (bestFont, bestSplit.map { (text: $0, pageIndex: 0) })
    }

    /// Finds the largest font (0.5pt steps) where every column still fits.
    private func refinedMaximumFontSize(
        for texts: [String],
        columnWidth: CGFloat,
        columnHeight: CGFloat,
        showsPageLabel: Bool
    ) -> CGFloat {
        guard !texts.isEmpty else {
            return minimumFontSize
        }

        let textWidth = max(columnWidth - (columnPadding * 2), 1)
        let textAreaHeight = lyricsTextAreaHeight(columnHeight: columnHeight, showsPageLabel: showsPageLabel)

        var candidate = maximumFontSize
        while candidate >= minimumFontSize {
            let fits = texts.allSatisfy {
                measuredHeight(for: $0, width: textWidth, fontSize: candidate) <= textAreaHeight
            }
            if fits {
                return candidate
            }
            candidate -= 0.5
        }

        return minimumFontSize
    }

    private func refineFontSizeUpward(
        from fontSize: CGFloat,
        texts: [String],
        textWidth: CGFloat,
        textAreaHeight: CGFloat
    ) -> CGFloat {
        var best = fontSize
        var candidate = fontSize + 0.5
        while candidate <= maximumFontSize {
            let fits = texts.allSatisfy {
                measuredHeight(for: $0, width: textWidth, fontSize: candidate) <= textAreaHeight
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

    /// Chooses a split that fits and leaves the least bottom slack in the last column.
    private func optimalTwoColumnSplit(
        lines: [String],
        fontSize: CGFloat,
        textWidth: CGFloat,
        textAreaHeight: CGFloat
    ) -> [String]? {
        guard lines.count > 1 else {
            let text = lines.first ?? ""
            let height = measuredHeight(for: text, width: textWidth, fontSize: fontSize)
            return height <= textAreaHeight ? [text, ""] : nil
        }

        var bestSplit: [String]?
        var bestLastSlack = CGFloat.greatestFiniteMagnitude

        for splitIndex in 1..<lines.count {
            let left = lines[0..<splitIndex].joined(separator: "\n")
            let right = lines[splitIndex...].joined(separator: "\n")
            let leftHeight = measuredHeight(for: left, width: textWidth, fontSize: fontSize)
            let rightHeight = measuredHeight(for: right, width: textWidth, fontSize: fontSize)

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

    private func splittableLineGroups(from text: String) -> [String] {
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

    private func defaultTwoColumnSplit(for text: String) -> [String] {
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

    private func lyricsTextAreaHeight(columnHeight: CGFloat, showsPageLabel: Bool) -> CGFloat {
        var overhead = columnPadding * 2
        if showsPageLabel {
            overhead += pageLabelOverhead
        }
        return max(columnHeight - overhead, 1)
    }

    private func measuredHeight(for text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        guard !text.isEmpty else {
            return 0
        }

        let visible = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "~~", with: "")

        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        label.text = visible

        return ceil(
            label.sizeThatFits(
                CGSize(width: width, height: .greatestFiniteMagnitude)
            ).height
        )
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 34, weight: .bold))
                    .lineLimit(1)

                if let startsOn = song.startsOn, !startsOn.isEmpty {
                    Text("Starts on \(startsOn)")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer()

            Text(screenLabel)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(height: 56)
    }

    private var screenLabel: String {
        if pages.count <= columnsPerScreen {
            return "Page \(pages.count == 1 ? "1" : "1–\(pages.count)") / \(max(pages.count, 1))"
        }

        let startPage = selectedScreen * columnsPerScreen + 1
        let endPage = min((selectedScreen + 1) * columnsPerScreen, pages.count)
        return "Pages \(startPage)–\(endPage) / \(pages.count)"
    }

    private func columnWidth(usableWidth: CGFloat, columnSpacing: CGFloat, columns: Int) -> CGFloat {
        guard columns > 0 else {
            return usableWidth
        }

        let totalSpacing = columnSpacing * CGFloat(max(columns - 1, 0))
        return (usableWidth - totalSpacing) / CGFloat(columns)
    }

    private func pageColumn(
        text: String,
        pageIndex: Int,
        width: CGFloat,
        height: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if pages.count > 1 {
                Text("Page \(pageIndex + 1)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
            }

            HighlightedLyricsText(text: text, fontSize: fontSize)
                .foregroundStyle(.white)
        }
        .padding(columnPadding)
        .frame(width: width, height: height, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
