import SwiftUI
import UIKit

struct LyricsView: View {
    let song: Song
    @State private var currentPageIndex: Int = 0
    @State private var pages: [NSAttributedString] = []
    @Environment(\.dismiss) var dismiss
    
    private let font = UIFont.systemFont(ofSize: 18, weight: .bold)
    private let minimumSwipeDistance: CGFloat = 50
    private let backButtonSize: CGFloat = 30
    private let pillSize = CGSize(width: 44, height: 26)
    private var topRightControlSize: CGSize {
        CGSize(width: backButtonSize * 1.5, height: backButtonSize * 3)
    }
    
    private static let allNotes: [String] = [
        "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#",
        "Am", "A#m", "Bm", "Cm", "C#m", "Dm", "D#m", "Em", "Fm", "F#m", "Gm", "G#m",
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                if !pages.isEmpty {
                    VStack {
                        Spacer()
                        AttributedText(
                            attributedString: pages[currentPageIndex],
                            topRightExclusionSize: topRightControlSize
                        )
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                tabPillsLayer(in: geometry.size)
                
                if pages.count > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(currentPageIndex + 1)/\(pages.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black.opacity(0.45))
                                .padding(.trailing, 18)
                                .padding(.bottom, 10)
                        }
                    }
                }
                
                VStack {
                    HStack {
                        Spacer()
                        topRightControl
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                    }
                    Spacer()
                }
                .zIndex(100)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: minimumSwipeDistance)
                    .onEnded { value in
                        handleSwipe(value.translation)
                    }
            )
            .onAppear {
                calculatePages()
            }
            .background(
                KeyCommandHandler(
                    onUpArrow: { goToPreviousPage() },
                    onDownArrow: { goToNextPage() }
                )
            )
        }
        .navigationBarHidden(true)
    }
    
    private var topRightControl: some View {
        VStack(spacing: 4) {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: backButtonSize))
                    .foregroundColor(.black)
            }
            .accessibilityLabel("Back")
            
            if let startsOn = song.startsOn, !startsOn.isEmpty {
                Text(startsOn)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(
            width: topRightControlSize.width,
            height: topRightControlSize.height,
            alignment: .topTrailing
        )
    }
    
    @ViewBuilder
    private func tabPillsLayer(in screenSize: CGSize) -> some View {
        if screenSize.width > 0, screenSize.height > 0 {
            let placements = currentPagePlacements()
            
            ZStack(alignment: .topLeading) {
                ForEach(Self.allNotes, id: \.self) { note in
                    TabPillView(note: note)
                        .frame(width: pillSize.width, height: pillSize.height)
                        .position(
                            position(
                                for: note,
                                placements: placements,
                                screenSize: screenSize
                            )
                        )
                }
            }
            .frame(width: screenSize.width, height: screenSize.height)
            .allowsHitTesting(false)
            .zIndex(50)
        }
    }
    
    private func currentPagePlacements() -> [String: TabPlacement] {
        let placements = song.tabs.placements(forPageIndex: currentPageIndex)
        var dictionary: [String: TabPlacement] = [:]
        for placement in placements {
            dictionary[placement.note] = placement
        }
        return dictionary
    }
    
    private func position(
        for note: String,
        placements: [String: TabPlacement],
        screenSize: CGSize
    ) -> CGPoint {
        let maxX = max(screenSize.width - pillSize.width, 1)
        let maxY = max(screenSize.height - pillSize.height, 1)
        
        let topLeft: CGPoint
        if let placement = placements[note] {
            topLeft = CGPoint(
                x: CGFloat(placement.x) * screenSize.width,
                y: CGFloat(placement.y) * screenSize.height
            )
        } else {
            topLeft = defaultTopLeft(for: note, in: screenSize)
        }
        
        let clampedX = min(max(topLeft.x, 0), maxX)
        let clampedY = min(max(topLeft.y, 0), maxY)
        
        return CGPoint(x: clampedX + pillSize.width / 2, y: clampedY + pillSize.height / 2)
    }
    
    private func defaultTopLeft(for note: String, in screenSize: CGSize) -> CGPoint {
        let columns = 6
        let index = Self.allNotes.firstIndex(of: note) ?? 0
        let column = index % columns
        let row = index / columns
        let x = (0.04 + Double(column) * 0.15) * screenSize.width
        let y = (0.04 + Double(row) * 0.07) * screenSize.height
        return CGPoint(x: x, y: y)
    }
    
    private func calculatePages() {
        let lyricsText = song.lyrics.replacingOccurrences(of: "\\n", with: "\n")
        let pageStrings = LyricsPaginator.splitByPageMarkers(lyricsText)
        
        pages = pageStrings.map { pageText in
            HighlightedText.processFullText(pageText, font: font)
        }
        
        currentPageIndex = min(currentPageIndex, pages.count - 1)
    }
    
    private func goToPreviousPage() {
        if currentPageIndex > 0 {
            currentPageIndex -= 1
        }
    }
    
    private func goToNextPage() {
        if currentPageIndex < pages.count - 1 {
            currentPageIndex += 1
        }
    }
    
    private func handleSwipe(_ translation: CGSize) {
        guard abs(translation.width) > abs(translation.height),
              abs(translation.width) >= minimumSwipeDistance else {
            return
        }
        
        if translation.width < 0 {
            goToNextPage()
        } else {
            goToPreviousPage()
        }
    }
}

private struct TabPillView: View {
    let note: String
    
    var body: some View {
        Text(note)
            .font(.system(size: 12, weight: .heavy))
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color(red: 1.0, green: 0.98, blue: 0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(Color.black, lineWidth: 1.5)
            )
    }
}
