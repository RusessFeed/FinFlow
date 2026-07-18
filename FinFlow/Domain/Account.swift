import Foundation

struct Account: Codable, Equatable, Identifiable {
    enum Kind: String, Codable, CaseIterable {
        case checking
        case savings
        case cash
        case credit
    }

    let id: UUID
    var name: String
    var kind: Kind
    var balance: Money
    var iconName: String
    var tintHex: String

    init(
        id: UUID = UUID(),
        name: String,
        kind: Kind,
        balance: Money,
        iconName: String,
        tintHex: String
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.balance = balance
        self.iconName = iconName
        self.tintHex = tintHex
    }
}
