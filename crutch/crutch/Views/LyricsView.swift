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
    private let pillSize = CGSize(width: 32, height: 18)
    private var topRightControlSize: CGSize {
        CGSize(width: backButtonSize * 1.5, height: backButtonSize * 3)
    }
    
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
            let placements = song.tabs.placements(forPageIndex: currentPageIndex)
            
            ZStack(alignment: .topLeading) {
                ForEach(placements) { placement in
                    TabPillView(note: placement.note)
                        .frame(width: pillSize.width, height: pillSize.height)
                        .position(position(for: placement, screenSize: screenSize))
                }
            }
            .frame(width: screenSize.width, height: screenSize.height)
            .allowsHitTesting(false)
            .zIndex(50)
        }
    }
    
    private func position(for placement: TabPlacement, screenSize: CGSize) -> CGPoint {
        let maxX = max(screenSize.width - pillSize.width, 1)
        let maxY = max(screenSize.height - pillSize.height, 1)
        let topLeftX = CGFloat(placement.x) * screenSize.width
        let topLeftY = CGFloat(placement.y) * screenSize.height
        let clampedX = min(max(topLeftX, 0), maxX)
        let clampedY = min(max(topLeftY, 0), maxY)
        return CGPoint(x: clampedX + pillSize.width / 2, y: clampedY + pillSize.height / 2)
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
            .font(.system(size: 10, weight: .heavy))
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(Color(red: 1.0, green: 0.98, blue: 0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color.black, lineWidth: 1.25)
            )
    }
}
