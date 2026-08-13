import Foundation

struct SpendingCategory: Codable, Equatable, Identifiable {
    let id: UUID
    var name: String
    var iconName: String
    var tintHex: String

    init(id: UUID = UUID(), name: String, iconName: String, tintHex: String) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.tintHex = tintHex
    }
}
