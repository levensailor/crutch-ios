import SwiftUI

struct LyricsColumnsView: View {
    let song: Song

    private let horizontalPadding: CGFloat = 24
    private let verticalPadding: CGFloat = 18
    private let columnSpacing: CGFloat = 14
    private let headerHeight: CGFloat = 72
    private let columnPadding: CGFloat = 9

    @State private var pages: [String] = []
    @State private var screenLayouts: [LyricsLayoutEngine.ScreenLayout] = []
    @State private var selectedScreen = 0
    @State private var preparedSongID: UUID?

    private var columnsPerScreen: Int {
        LyricsLayoutEngine.columnsPerScreen(for: pages.count)
    }

    private var screenCount: Int {
        max(screenLayouts.count, 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let usableWidth = geometry.size.width - (horizontalPadding * 2)
            let usableHeight = geometry.size.height - verticalPadding * 2 - headerHeight
            let metrics = LyricsLayoutEngine.Metrics(
                usableWidth: usableWidth,
                usableHeight: usableHeight,
                columnSpacing: columnSpacing,
                columnsPerScreen: LyricsLayoutEngine.columnsPerScreen(for: max(pages.count, 1))
            )

            VStack(alignment: .leading, spacing: 16) {
                header

                if screenLayouts.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    lyricsPager(metrics: metrics)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .task(id: layoutTaskKey(metrics: metrics)) {
                await prepareLayouts(metrics: metrics)
            }
        }
        .background(Color.black)
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private func lyricsPager(metrics: LyricsLayoutEngine.Metrics) -> some View {
        let columnWidth = LyricsLayoutEngine.columnWidth(
            usableWidth: metrics.usableWidth,
            columnSpacing: metrics.columnSpacing,
            columns: metrics.columnsPerScreen
        )

        TabView(selection: $selectedScreen) {
            ForEach(Array(screenLayouts.enumerated()), id: \.offset) { index, layout in
                screenRow(
                    layout: layout,
                    columnWidth: columnWidth,
                    columnHeight: metrics.usableHeight
                )
                .tag(index)
                .focusable(true)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: screenLayouts.count > 1 ? .automatic : .never))
    }

    @ViewBuilder
    private func screenRow(
        layout: LyricsLayoutEngine.ScreenLayout,
        columnWidth: CGFloat,
        columnHeight: CGFloat
    ) -> some View {
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

    private func layoutTaskKey(metrics: LyricsLayoutEngine.Metrics) -> String {
        "\(song.id.uuidString)-\(Int(metrics.usableWidth))-\(Int(metrics.usableHeight))-\(song.lyrics.count)"
    }

    @MainActor
    private func prepareLayouts(metrics: LyricsLayoutEngine.Metrics) async {
        if preparedSongID == song.id, !screenLayouts.isEmpty {
            return
        }

        screenLayouts = []
        let parsedPages = LyricsPaginator.splitByPageMarkers(song.lyrics)
        let layouts = await Task.detached(priority: .userInitiated) {
            LyricsLayoutEngine.computeAllScreenLayouts(pages: parsedPages, metrics: metrics)
        }.value

        pages = parsedPages
        screenLayouts = layouts
        preparedSongID = song.id
        selectedScreen = min(selectedScreen, max(layouts.count - 1, 0))
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
