import SwiftUI
import WidgetKit

struct CrutchStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> CrutchStatusEntry {
        CrutchStatusEntry(date: .now, title: "Crutch")
    }

    func getSnapshot(in context: Context, completion: @escaping (CrutchStatusEntry) -> Void) {
        completion(CrutchStatusEntry(date: .now, title: "Crutch"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CrutchStatusEntry>) -> Void) {
        let entry = CrutchStatusEntry(date: .now, title: "Crutch")
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct CrutchStatusEntry: TimelineEntry {
    let date: Date
    let title: String
}

struct CrutchStatusWidgetView: View {
    var entry: CrutchStatusEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "music.note.list")
                .font(.system(size: 18, weight: .bold))
            Text(entry.title)
                .font(.system(size: 16, weight: .bold))
            Text("Open a song to show its title in the Dynamic Island.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct CrutchStatusWidget: Widget {
    let kind = "CrutchStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CrutchStatusProvider()) { entry in
            CrutchStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Crutch")
        .description("Shows that Crutch Live Activities are installed.")
        .supportedFamilies([.systemSmall])
    }
}
