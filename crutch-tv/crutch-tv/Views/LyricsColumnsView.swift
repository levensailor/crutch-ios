import SwiftUI

struct LyricsColumnsView: View {
    let song: Song

    private let columnsPerScreen = 3
    private let baseFontSize: CGFloat = 42
    private let minimumFontSize: CGFloat = 28

    @State private var pages: [String] = []
    @State private var selectedScreen = 0

    private var screenCount: Int {
        max(1, Int(ceil(Double(max(pages.count, 1)) / Double(columnsPerScreen))))
    }

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 48
            let verticalPadding: CGFloat = 36
            let columnSpacing: CGFloat = 28
            let headerHeight: CGFloat = 72
            let usableWidth = geometry.size.width - (horizontalPadding * 2)
            let usableHeight = geometry.size.height - verticalPadding * 2 - headerHeight
            let columnWidth = (usableWidth - columnSpacing * CGFloat(columnsPerScreen - 1)) / CGFloat(columnsPerScreen)
            let fontSize = fittedFontSize(
                for: pages,
                columnWidth: columnWidth,
                columnHeight: usableHeight
            )

            VStack(alignment: .leading, spacing: 16) {
                header

                TabView(selection: $selectedScreen) {
                    ForEach(0..<screenCount, id: \.self) { screenIndex in
                        HStack(alignment: .top, spacing: columnSpacing) {
                            ForEach(0..<columnsPerScreen, id: \.self) { columnIndex in
                                let pageIndex = screenIndex * columnsPerScreen + columnIndex
                                if pageIndex < pages.count {
                                    pageColumn(
                                        text: pages[pageIndex],
                                        pageIndex: pageIndex,
                                        width: columnWidth,
                                        height: usableHeight,
                                        fontSize: fontSize
                                    )
                                } else {
                                    Color.clear
                                        .frame(width: columnWidth, height: usableHeight)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        let startPage = selectedScreen * columnsPerScreen + 1
        let endPage = min((selectedScreen + 1) * columnsPerScreen, max(pages.count, 1))
        return "Pages \(startPage)–\(endPage) / \(max(pages.count, 1))"
    }

    private func pageColumn(
        text: String,
        pageIndex: Int,
        width: CGFloat,
        height: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Page \(pageIndex + 1)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white.opacity(0.45))

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
