import SwiftUI
import UIKit
import WidgetKit

struct MarqueeTitleView: View {
    let text: String
    var font: Font = .system(size: 13, weight: .bold)
    var speedPointsPerSecond: CGFloat = 28

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
            GeometryReader { geometry in
                let availableWidth = max(geometry.size.width, 1)
                let measuredWidth = textWidth(text, font: uiFont(for: font))
                let shouldScroll = measuredWidth > availableWidth + 2
                let loopWidth = measuredWidth + 28
                let elapsed = context.date.timeIntervalSinceReferenceDate
                let offset = shouldScroll
                    ? CGFloat(elapsed.truncatingRemainder(dividingBy: Double(loopWidth / speedPointsPerSecond)))
                        * -speedPointsPerSecond
                    : 0

                HStack(spacing: 28) {
                    Text(text)
                        .font(font)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    if shouldScroll {
                        Text(text)
                            .font(font)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .offset(x: shouldScroll ? offset : max((availableWidth - measuredWidth) / 2, 0))
                .frame(width: availableWidth, alignment: .leading)
                .clipped()
            }
        }
    }

    private func uiFont(for font: Font) -> UIFont {
        UIFont.systemFont(ofSize: 13, weight: .bold)
    }

    private func textWidth(_ value: String, font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return ceil((value as NSString).size(withAttributes: attributes).width)
    }
}
