import UIKit
import SwiftUI

class LyricsPaginator {
    // Split text by ##### markers and remove the markers from the resulting pages
    static func splitByPageMarkers(_ lyrics: String) -> [String] {
        let text = lyrics.replacingOccurrences(of: "\\n", with: "\n")
        
        if text.isEmpty {
            return [""]
        }
        
        // Split by ##### markers (can be on their own line or at start/end of line)
        let lines = text.components(separatedBy: .newlines)
        var pages: [String] = []
        var currentPage: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if this line is a page marker (#####)
            if trimmedLine == "#####" || trimmedLine.hasPrefix("#####") || trimmedLine.hasSuffix("#####") {
                // End current page if it has content
                if !currentPage.isEmpty {
                    pages.append(currentPage.joined(separator: "\n"))
                    currentPage = []
                }
                // Skip the marker line
                continue
            }
            
            // Add line to current page
            currentPage.append(line)
        }
        
        // Add final page if it has content
        if !currentPage.isEmpty {
            pages.append(currentPage.joined(separator: "\n"))
        }
        
        // Ensure at least one page exists
        if pages.isEmpty {
            pages.append(text)
        }
        
        return pages
    }
}



