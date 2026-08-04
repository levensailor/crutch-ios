import SwiftUI

struct SongsListView: View {
    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var isSavingVisibility = false
    @State private var isEditingVisibility = false
    @State private var loadError: String?
    
    private let repository = LyricsRepository()
    
    private var displayedSongs: [Song] {
        if isEditingVisibility {
            return songs
        }
        
        return songs.filter { !$0.isHidden }
    }
    
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
            
            ForEach(displayedSongs) { song in
                if isEditingVisibility {
                    Button {
                        toggleVisibility(for: song.id)
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: song.isHidden ? "square" : "checkmark.square.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(song.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(song.isHidden ? .gray : .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.white)
                } else {
                    NavigationLink(destination: LyricsView(song: song)) {
                        Text(song.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .padding()
                    }
                    .listRowBackground(Color.white)
                }
            }
            
            if !songs.isEmpty {
                Section {
                    Button {
                        Task {
                            await handleVisibilityAction()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSavingVisibility {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isEditingVisibility ? "save" : "show/hide")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .textCase(nil)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .disabled(isSavingVisibility || isLoading)
                    .listRowBackground(Color.white)
                }
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
    
    private func toggleVisibility(for songId: UUID) {
        guard let index = songs.firstIndex(where: { $0.id == songId }) else {
            return
        }
        
        songs[index].isHidden.toggle()
    }
    
    private func handleVisibilityAction() async {
        if isEditingVisibility {
            await saveVisibility()
        } else {
            isEditingVisibility = true
        }
    }
    
    private func saveVisibility() async {
        isSavingVisibility = true
        loadError = nil
        
        do {
            let updates = songs.map { song in
                (id: song.id, isHidden: song.isHidden)
            }
            try await repository.updateSongVisibility(updates)
            await loadSongs()
            isEditingVisibility = false
        } catch {
            loadError = "Could not save show/hide changes."
        }
        
        isSavingVisibility = false
    }
}
