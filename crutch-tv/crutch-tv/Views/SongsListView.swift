import SwiftUI

struct SongsListView: View {
    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var searchText = ""

    private let repository = LyricsRepository()

    private var visibleSongs: [Song] {
        let base = songs.filter { !$0.isHidden }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return base
        }

        return base.filter { song in
            song.title.localizedCaseInsensitiveContains(query)
                || (song.startsOn?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        Group {
            if isLoading && songs.isEmpty {
                ProgressView("Loading lyrics…")
                    .font(.title2)
            } else if let loadError, songs.isEmpty {
                ContentUnavailableView(
                    "Lyrics unavailable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else if visibleSongs.isEmpty {
                ContentUnavailableView.search(text: searchText.isEmpty ? "songs" : searchText)
            } else {
                List(visibleSongs) { song in
                    NavigationLink(value: song) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(song.title)
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(.primary)

                            if let startsOn = song.startsOn, !startsOn.isEmpty {
                                Text("Starts on \(startsOn)")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Crutch")
        .navigationDestination(for: Song.self) { song in
            LyricsColumnsView(song: song)
        }
        .searchable(text: $searchText, prompt: "Search songs")
        .task {
            await loadSongs()
        }
        .refreshable {
            await loadSongs()
        }
    }

    private func loadSongs() async {
        isLoading = true
        let loaded = await repository.loadSongs()
        songs = loaded
        loadError = loaded.isEmpty ? "No lyrics are available from the feed or offline cache." : nil
        isLoading = false
    }
}
