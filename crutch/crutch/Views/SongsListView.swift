import SwiftUI

struct SongsListView: View {
    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var loadError: String?
    
    private let repository = LyricsRepository()
    
    var body: some View {
        List {
            if isLoading && songs.isEmpty {
                Text("Loading lyrics...")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gray)
                    .padding()
                    .listRowBackground(Color.white)
            }
            
            if let loadError, songs.isEmpty {
                Text(loadError)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
                    .padding()
                    .listRowBackground(Color.white)
            }
            
            ForEach(songs) { song in
                NavigationLink(destination: LyricsView(song: song)) {
                    Text(song.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .padding()
                }
                .listRowBackground(Color.white)
            }
        }
        .background(Color.white)
        .scrollContentBackground(.hidden)
        .task {
            await loadSongs()
        }
        .refreshable {
            await loadSongs()
        }
    }
    
    private func loadSongs() async {
        isLoading = true
        let loadedSongs = await repository.loadSongs()
        songs = loadedSongs
        loadError = loadedSongs.isEmpty ? "No lyrics are available." : nil
        isLoading = false
    }
}


