// iOS 26+ only. No #available guards.

import SwiftUI

struct HighlightedText: View {
    let text: String
    let ranges: [Range<String.Index>]
    let highlightColor: Color

    var body: some View {
        if ranges.isEmpty {
            Text(text).foregroundStyle(Color.textPrimary)
        } else {
            buildAttributed()
        }
    }

    private func buildAttributed() -> some View {
        var result = AttributedString(text)
        result.foregroundColor = UIColor(Color.textPrimary)
        for range in ranges {
            if let attrRange = Range(range, in: result) {
                result[attrRange].foregroundColor = UIColor(highlightColor)
                result[attrRange].font = .systemFont(ofSize: 17, weight: .semibold)
            }
        }
        return Text(result)
    }
}
