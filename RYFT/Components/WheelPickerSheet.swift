// iOS 26+ only. No #available guards.

import SwiftUI

/// A bottom sheet presenting a native wheel Picker for precise value selection.
struct WheelPickerSheet: View {
    @Binding var value: Double
    let values: [Double]
    let format: (Double) -> String
    let onDone: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundStyle(Color.textMuted)
                Spacer()
                Button("Done", action: onDone)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.xs)

            Picker("", selection: $value) {
                ForEach(values, id: \.self) { v in
                    Text(format(v)).tag(v)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 180)
        }
    }
}

#Preview("Weight wheel") {
    @Previewable @State var value = 135.0
    let values = stride(from: 0.0, through: 999.0, by: 1.0).map { $0 }
    WheelPickerSheet(
        value: $value,
        values: values,
        format: { v in v.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(v))" : String(format: "%.1f", v) },
        onDone: {},
        onCancel: {}
    )
    .presentationDetents([.height(260)])
}
