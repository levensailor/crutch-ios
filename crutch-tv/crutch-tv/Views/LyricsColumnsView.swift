import SwiftUI

struct LyricsColumnsView: View {
    let song: Song

    private let minimumFontSize: CGFloat = 28

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

    private var screenCount: Int {
        if isSinglePageSpread {
            return 1
        }
        return max(1, Int(ceil(Double(max(pages.count, 1)) / Double(columnsPerScreen))))
    }

    private var baseFontSize: CGFloat {
        if isSinglePageSpread {
            return 58
        }
        switch columnsPerScreen {
        case 2:
            return 46
        default:
            return 42
        }
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
            let fontSize = fittedFontSize(
                for: fontSizingTexts,
                columnWidth: columnWidth,
                columnHeight: usableHeight
            )

            VStack(alignment: .leading, spacing: 16) {
                header

                TabView(selection: $selectedScreen) {
                    ForEach(0..<screenCount, id: \.self) { screenIndex in
                        screenRow(
                            screenIndex: screenIndex,
                            columnWidth: columnWidth,
                            columnHeight: usableHeight,
                            columnSpacing: columnSpacing,
                            fontSize: fontSize
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
        columnSpacing: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        let columns = columnContents(for: screenIndex)

        HStack(alignment: .top, spacing: columnSpacing) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                pageColumn(
                    text: column.text,
                    pageIndex: column.pageIndex,
                    width: columnWidth,
                    height: columnHeight,
                    fontSize: fontSize
                )
            }

            if columns.count < columnsPerScreen {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var fontSizingTexts: [String] {
        if isSinglePageSpread {
            return splitAcrossColumns(pages[0], columns: columnsPerScreen)
        }
        return pages
    }

    private func columnContents(for screenIndex: Int) -> [(text: String, pageIndex: Int)] {
        if isSinglePageSpread {
            return splitAcrossColumns(pages[0], columns: columnsPerScreen)
                .map { (text: $0, pageIndex: 0) }
        }

        let startPage = screenIndex * columnsPerScreen
        let endPage = min(startPage + columnsPerScreen, pages.count)
        return (startPage..<endPage).map { pageIndex in
            (text: pages[pageIndex], pageIndex: pageIndex)
        }
    }

    private func splitAcrossColumns(_ text: String, columns: Int) -> [String] {
        guard columns > 1 else {
            return [text]
        }

        let lines = text.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            return Array(repeating: text, count: columns)
        }

        var result = Array(repeating: [String](), count: columns)
        let targetLines = Int(ceil(Double(lines.count) / Double(columns)))
        var lineIndex = 0

        for column in 0..<columns {
            let end = min(lineIndex + targetLines, lines.count)
            if lineIndex < end {
                result[column] = Array(lines[lineIndex..<end])
                lineIndex = end
            }
        }

        return result.map { $0.joined(separator: "\n") }
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
        .padding(9)
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

    private func fittedFontSize(for pages: [String], columnWidth: CGFloat, columnHeight: CGFloat) -> CGFloat {
        guard columnWidth > 0, columnHeight > 0 else {
            return baseFontSize
        }

        var size = baseFontSize
        while size > minimumFontSize {
            let fitsAll = pages.allSatisfy { page in
                estimatedHeight(for: page, width: columnWidth - 18, fontSize: size) <= columnHeight - 24
            }
            if fitsAll {
                return size
            }
            size -= 2
        }
        return minimumFontSize
    }

    private func estimatedHeight(for text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        let lines = text.components(separatedBy: .newlines)
        let averageCharsPerLine = max(Int(width / (fontSize * 0.55)), 8)
        var totalLines = 0

        for line in lines {
            let visible = line
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "~~", with: "")
            let length = max(visible.count, 1)
            totalLines += Int(ceil(Double(length) / Double(averageCharsPerLine)))
        }

        let lineHeight = fontSize * 1.22
        return CGFloat(totalLines) * lineHeight
    }
}
