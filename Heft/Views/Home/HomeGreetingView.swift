// iOS 26+ only. No #available guards.

import SwiftUI

struct HomeGreetingView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now.formatted(.dateTime.weekday(.wide)))
                .font(Typography.caption)
                .foregroundStyle(Color.textFaint)
                .textCase(.uppercase)
                .tracking(1)
            Text("Ready to lift?")
                .font(Typography.display)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
        }
    }
}

#Preview {
    HomeGreetingView()
        .padding()
        .preferredColorScheme(.dark)
}
