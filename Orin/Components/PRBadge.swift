// iOS 26+ only. No #available guards.

import SwiftUI

struct PRBadge: View {
    var body: some View {
        Text("PR")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.OrinAmber)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.OrinAmber.opacity(0.14), in: Capsule())
    }
}

#Preview {
    PRBadge()
        .padding()
        .preferredColorScheme(.dark)
}
