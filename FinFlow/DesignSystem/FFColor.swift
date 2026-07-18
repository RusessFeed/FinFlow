import SwiftUI

enum FFColor {
    static let accent = Color(hex: "#6C5CE7")
    static let positive = Color(hex: "#00B894")
    static let warning = Color(hex: "#FDCB6E")
    static let negative = Color(hex: "#E17055")
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let secondaryText = Color(uiColor: .secondaryLabel)
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let value = UInt64(clean, radix: 16) ?? 0
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
