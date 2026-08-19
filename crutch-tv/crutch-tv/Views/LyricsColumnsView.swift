import SwiftUI

struct LyricsColumnsView: View {
    let song: Song

    private let minimumFontSize: CGFloat = 28

    @State private var pages: [String] = []
    @State private var selectedScreen = 0

    /// 1-page songs use one full-width column; 2-page songs use two; 3+ paginate in threes.
    private var columnsPerScreen: Int {
        switch pages.count {
        case 0, 1:
            return 1
        case 2:
            return 2
        default:
            return 3
        }
    }

    private var screenCount: Int {
        max(1, Int(ceil(Double(max(pages.count, 1)) / Double(columnsPerScreen))))
    }

    private var baseFontSize: CGFloat {
        switch columnsPerScreen {
        case 1:
            return 52
        case 2:
            return 46
        default:
            return 42
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 48
            let verticalPadding: CGFloat = 36
            let columnSpacing: CGFloat = 28
            let headerHeight: CGFloat = 72
            let usableWidth = geometry.size.width - (horizontalPadding * 2)
            let usableHeight = geometry.size.height - verticalPadding * 2 - headerHeight
            let columnWidth = columnWidth(
                usableWidth: usableWidth,
                columnSpacing: columnSpacing,
                columns: columnsPerScreen
            )
            let fontSize = fittedFontSize(
                for: pages,
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
        let startPage = screenIndex * columnsPerScreen
        let endPage = min(startPage + columnsPerScreen, pages.count)
        let pageIndices = startPage..<endPage

        HStack(alignment: .top, spacing: columnSpacing) {
            ForEach(Array(pageIndices), id: \.self) { pageIndex in
                pageColumn(
                    text: pages[pageIndex],
                    pageIndex: pageIndex,
                    width: columnWidth,
                    height: columnHeight,
                    fontSize: fontSize
                )
            }

            if pageIndices.count < columnsPerScreen {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        .padding(18)
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
                estimatedHeight(for: page, width: columnWidth - 36, fontSize: size) <= columnHeight - 48
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
