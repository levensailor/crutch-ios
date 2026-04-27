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
    
    private func calculatePages() {
        let lyricsText = song.lyrics.replacingOccurrences(of: "\\n", with: "\n")
        
        // Split by ##### markers first
        let pageStrings = LyricsPaginator.splitByPageMarkers(lyricsText)
        
        // Process highlights on each page separately
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


