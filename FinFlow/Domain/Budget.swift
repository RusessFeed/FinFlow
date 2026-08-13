import Foundation

struct Budget: Codable, Equatable, Identifiable {
    let id: UUID
    var categoryID: UUID
    var monthlyLimit: Money

    init(id: UUID = UUID(), categoryID: UUID, monthlyLimit: Money) {
        self.id = id
        self.categoryID = categoryID
        self.monthlyLimit = monthlyLimit
    }
}

struct BudgetDraft {
    let categoryID: UUID
    let monthlyLimit: Money
}
