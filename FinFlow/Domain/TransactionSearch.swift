import Foundation

enum TransactionKindFilter: String, CaseIterable, Identifiable {
    case all
    case income
    case expenses

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All"
        case .income: "Income"
        case .expenses: "Expenses"
        }
    }

    func matches(_ kind: FinancialTransaction.Kind) -> Bool {
        switch self {
        case .all: true
        case .income: kind == .income
        case .expenses: kind == .expense
        }
    }
}

struct TransactionSearchFilter: Equatable {
    var query: String = ""
    var kind: TransactionKindFilter = .all
    var categoryID: UUID?
}

enum TransactionSearch {
    static func filter(
        transactions: [FinancialTransaction],
        accounts: [Account],
        categories: [SpendingCategory],
        filter: TransactionSearchFilter
    ) -> [FinancialTransaction] {
        let normalizedQuery = normalize(filter.query)
        return transactions.filter { transaction in
            guard filter.kind.matches(transaction.kind) else { return false }
            if let categoryID = filter.categoryID, transaction.categoryID != categoryID {
                return false
            }
            guard !normalizedQuery.isEmpty else { return true }
            return searchableText(
                transaction: transaction,
                account: accounts.first { $0.id == transaction.accountID },
                category: categories.first { $0.id == transaction.categoryID }
            )
            .contains(normalizedQuery)
        }
        .sorted { $0.date > $1.date }
    }

    private static func searchableText(
        transaction: FinancialTransaction,
        account: Account?,
        category: SpendingCategory?
    ) -> String {
        normalize([
            transaction.title,
            transaction.note,
            account?.name,
            category?.name,
            transaction.amount.formatted(locale: Locale(identifier: "en_US"))
        ]
        .compactMap { $0 }
        .joined(separator: " "))
    }

    private static func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
