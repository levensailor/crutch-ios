import ActivityKit
import SwiftUI
import WidgetKit

@main
struct CrutchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SongTitleLiveActivity()
    }
}

struct SongTitleLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SongPerformanceAttributes.self) { context in
            lockScreenView(for: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    MarqueeTitleView(text: context.state.title, font: .system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.songCount > 1 {
                        Text("\(context.state.songIndex)/\(context.state.songCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .monospacedDigit()
                            .padding(.trailing, 4)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                }
            } compactLeading: {
                Image(systemName: "music.note")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            } compactTrailing: {
                MarqueeTitleView(text: context.state.title, font: .system(size: 12, weight: .bold))
                    .frame(width: 88, alignment: .leading)
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "music.note")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private func lockScreenView(
        for context: ActivityViewContext<SongPerformanceAttributes>
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                MarqueeTitleView(text: context.state.title, font: .system(size: 17, weight: .bold))
                    .frame(height: 22)
                    .foregroundStyle(.white)

                if context.state.songCount > 1 {
                    Text("Song \(context.state.songIndex) of \(context.state.songCount)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}
