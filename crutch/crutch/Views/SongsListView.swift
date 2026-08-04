import SwiftUI
import UIKit

struct SongsListView: View {
    /// Matches iOS home-screen / Music-style drag initiation better than a 1.5s hold.
    private static let reorderLongPressDuration: Double = 0.5
    
    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var isSavingVisibility = false
    @State private var isSavingOrder = false
    @State private var isEditingVisibility = false
    @State private var isReordering = false
    @State private var editMode: EditMode = .inactive
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
            
            if let loadError, !loadError.isEmpty {
                Text(loadError)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
                    .padding()
                    .listRowBackground(Color.white)
            }
            
            ForEach(displayedSongs) { song in
                songRow(for: song)
                    .listRowBackground(Color.white)
            }
            .onMove { source, destination in
                guard isReordering else {
                    return
                }
                
                moveDisplayedSongs(from: source, to: destination)
            }
            
            if !songs.isEmpty {
                Section {
                    if isReordering {
                        Button {
                            finishReordering()
                        } label: {
                            centeredActionLabel(isSavingOrder ? "saving order..." : "done")
                        }
                        .disabled(isSavingOrder)
                        .listRowBackground(Color.white)
                    } else {
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
                        .disabled(isSavingVisibility || isLoading || isSavingOrder)
                        .listRowBackground(Color.white)
                    }
                }
            }
        }
        .background(Color.white)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, $editMode)
        .task {
            await loadSongs()
        }
        .refreshable {
            guard !isReordering, !isEditingVisibility else {
                return
            }
            await loadSongs()
        }
    }
    
    @ViewBuilder
    private func songRow(for song: Song) -> some View {
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
        } else if isReordering {
            Text(song.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            NavigationLink(destination: LyricsView(setlist: displayedSongs, startingAt: song.id)) {
                Text(song.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .padding()
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: Self.reorderLongPressDuration)
                    .onEnded { _ in
                        beginReordering()
                    }
            )
        }
    }
    
    private func centeredActionLabel(_ title: String) -> some View {
        HStack {
            Spacer()
            if isSavingOrder {
                ProgressView()
                    .padding(.trailing, 8)
            }
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .textCase(nil)
            Spacer()
        }
        .padding(.vertical, 8)
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
    
    private func beginReordering() {
        guard !isEditingVisibility, !isSavingOrder, displayedSongs.count > 1 else {
            return
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isReordering = true
        withAnimation {
            editMode = .active
        }
    }
    
    private func finishReordering() {
        isReordering = false
        withAnimation {
            editMode = .inactive
        }
    }
    
    private func moveDisplayedSongs(from source: IndexSet, to destination: Int) {
        var visibleSongs = songs.filter { !$0.isHidden }
        visibleSongs.move(fromOffsets: source, toOffset: destination)
        
        var visibleIterator = visibleSongs.makeIterator()
        songs = songs.map { song in
            if song.isHidden {
                return song
            }
            
            return visibleIterator.next() ?? song
        }
        
        Task {
            await persistOrder()
        }
    }
    
    private func persistOrder() async {
        isSavingOrder = true
        loadError = nil
        
        do {
            try await repository.reorderSongs(songs.map(\.id))
        } catch {
            loadError = "Could not save song order."
            await loadSongs()
        }
        
        isSavingOrder = false
    }
}
