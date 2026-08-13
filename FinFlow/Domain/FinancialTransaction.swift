import Foundation

struct FinancialTransaction: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case income
        case expense
        case transfer
    }

    let id: UUID
    var accountID: UUID
    var categoryID: UUID?
    var title: String
    var amount: Money
    var kind: Kind
    var date: Date
    var note: String?

    init(
        id: UUID = UUID(),
        accountID: UUID,
        categoryID: UUID? = nil,
        title: String,
        amount: Money,
        kind: Kind,
        date: Date = .now,
        note: String? = nil
    ) {
        self.id = id
        self.accountID = accountID
        self.categoryID = categoryID
        self.title = title
        self.amount = amount
        self.kind = kind
        self.date = date
        self.note = note
    }
}
