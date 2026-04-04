// iOS 26+ only. No #available guards.

import Foundation
import SwiftData

@Model
final class BodyWeightEntry {
    var id: UUID = UUID()
    var date: Date = Date.now
    var weight: Double = 0
    var unit: String = "lbs"

    init(
        id: UUID = UUID(),
        date: Date = .now,
        weight: Double,
        unit: String
    ) {
        self.id = id
        self.date = date
        self.weight = weight
        self.unit = unit
    }
}
