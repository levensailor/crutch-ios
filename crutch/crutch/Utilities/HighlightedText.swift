import SwiftUI
import UIKit

struct HighlightedText: UIViewRepresentable {
    let text: String
    let font: UIFont
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.font = font
        textView.textColor = .black
        textView.backgroundColor = .white
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        let attributedString = createAttributedStringRebuilt(from: text, font: font)
        uiView.attributedText = attributedString
    }
    
    private func createAttributedString(from text: String, font: UIFont) -> NSAttributedString {
        return createAttributedStringWithOffsets(from: text, font: font)
    }
    
    private func createAttributedStringRebuilt(from text: String, font: UIFont) -> NSAttributedString {
        return createAttributedStringWithOffsets(from: text, font: font)
    }
    
    // Public static method to process full text with highlights
    static func processFullText(_ text: String, font: UIFont) -> NSAttributedString {
        let processor = HighlightedText(text: text, font: font)
        return processor.createAttributedStringWithOffsets(from: text, font: font)
    }
    
    private func createAttributedStringWithOffsets(from text: String, font: UIFont) -> NSAttributedString {
        // Process text line by line, only matching delimiters on the same line
        let lines = text.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var allHighlightRanges: [(range: NSRange, color: UIColor)] = []
        var currentOffset = 0
        
        for line in lines {
            var processedLine = line
            var lineHighlights: [(openIndex: Int, closeIndex: Int, color: UIColor)] = []
            
            // Find all **text** patterns on this line
            var searchIndex = 0
            while searchIndex < line.count {
                let openRange = (line as NSString).range(of: "**", options: [], range: NSRange(location: searchIndex, length: line.count - searchIndex))
                if openRange.location != NSNotFound {
                    let afterOpen = openRange.location + openRange.length
                    let closeRange = (line as NSString).range(of: "**", options: [], range: NSRange(location: afterOpen, length: line.count - afterOpen))
                    if closeRange.location != NSNotFound {
                        // Both delimiters are on the same line
                        lineHighlights.append((openIndex: openRange.location, closeIndex: closeRange.location, color: UIColor.systemPink.withAlphaComponent(0.3)))
                        searchIndex = closeRange.location + closeRange.length
                    } else {
                        break
                    }
                } else {
                    break
                }
            }
            
            // Find all ~~text~~ patterns on this line
            searchIndex = 0
            while searchIndex < line.count {
                let openRange = (line as NSString).range(of: "~~", options: [], range: NSRange(location: searchIndex, length: line.count - searchIndex))
                if openRange.location != NSNotFound {
                    let afterOpen = openRange.location + openRange.length
                    let closeRange = (line as NSString).range(of: "~~", options: [], range: NSRange(location: afterOpen, length: line.count - afterOpen))
                    if closeRange.location != NSNotFound {
                        // Both delimiters are on the same line
                        lineHighlights.append((openIndex: openRange.location, closeIndex: closeRange.location, color: UIColor.systemGreen.withAlphaComponent(0.3)))
                        searchIndex = closeRange.location + closeRange.length
                    } else {
                        break
                    }
                } else {
                    break
                }
            }
            
            // Sort matches by position (reverse for processing)
            lineHighlights.sort { $0.openIndex > $1.openIndex }
            
            // Remove markers and calculate highlight ranges
            var adjustedHighlights: [(range: NSRange, color: UIColor)] = []
            
            for match in lineHighlights {
                let contentLength = match.closeIndex - match.openIndex - 2
                
                // Calculate offset for markers removed before this match
                var removedBefore = 0
                for prevMatch in lineHighlights {
                    if prevMatch.openIndex > match.openIndex {
                        removedBefore += 4 // 2 opening + 2 closing
                    }
                }
                
                // Remove closing marker first
                var closingRemovedBefore = 0
                for prevMatch in lineHighlights {
                    if prevMatch.closeIndex > match.closeIndex {
                        closingRemovedBefore += 4
                    }
                }
                
                let closingLocation = match.closeIndex - closingRemovedBefore
                if closingLocation >= 0 && closingLocation + 2 <= processedLine.count {
                    processedLine = (processedLine as NSString).replacingCharacters(in: NSRange(location: closingLocation, length: 2), with: "")
                }
                
                // Remove opening marker
                let openingLocation = match.openIndex - removedBefore
                if openingLocation >= 0 && openingLocation + 2 <= processedLine.count {
                    processedLine = (processedLine as NSString).replacingCharacters(in: NSRange(location: openingLocation, length: 2), with: "")
                    
                    // Calculate highlight location after removing opening marker
                    let highlightLocation = openingLocation
                    if contentLength > 0 && highlightLocation >= 0 && highlightLocation + contentLength <= processedLine.count {
                        adjustedHighlights.append((range: NSRange(location: highlightLocation, length: contentLength), color: match.color))
                    }
                }
            }
            
            // Add highlights with global offset
            for highlight in adjustedHighlights {
                allHighlightRanges.append((range: NSRange(location: currentOffset + highlight.range.location, length: highlight.range.length), color: highlight.color))
            }
            
            processedLines.append(processedLine)
            currentOffset += processedLine.count + 1 // +1 for newline
        }
        
        // Join all processed lines
        let processedText = processedLines.joined(separator: "\n")
        
        // Create final attributed string
        let finalAttributedString = NSMutableAttributedString(string: processedText)
        let fullRange = NSRange(location: 0, length: processedText.count)
        finalAttributedString.addAttribute(NSAttributedString.Key.font, value: font, range: fullRange)
        finalAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.black, range: fullRange)
        
        // Apply highlights
        for highlight in allHighlightRanges {
            let safeRange = NSRange(
                location: max(0, min(highlight.range.location, processedText.count)),
                length: min(highlight.range.length, processedText.count - max(0, highlight.range.location))
            )
            if safeRange.location >= 0 && safeRange.length > 0 && safeRange.location + safeRange.length <= processedText.count {
                finalAttributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: highlight.color, range: safeRange)
            }
        }
        
        return finalAttributedString
    }
}

// New view for displaying attributed strings directly
struct AttributedText: UIViewRepresentable {
    let attributedString: NSAttributedString
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .white
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedString
    }
}


