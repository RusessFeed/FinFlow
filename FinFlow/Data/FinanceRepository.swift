import Foundation

@MainActor
protocol FinanceRepository {
    func fetchAccounts() throws -> [Account]
    func fetchCategories() throws -> [SpendingCategory]
    func fetchTransactions() throws -> [FinancialTransaction]
    func fetchBudgets() throws -> [Budget]
    func createAccount(_ draft: AccountDraft) throws
    func createTransaction(_ draft: TransactionDraft) throws
    func deleteTransaction(id: UUID) throws
    func upsertBudget(_ draft: BudgetDraft) throws
}

struct AccountDraft {
    let name: String
    let kind: Account.Kind
    let openingBalance: Money
    let iconName: String
    let tintHex: String
}

struct TransactionDraft {
    let accountID: UUID
    let categoryID: UUID?
    let title: String
    let amount: Money
    let kind: FinancialTransaction.Kind
    let date: Date
    let note: String?
}

enum FinanceRepositoryError: LocalizedError {
    case accountNotFound
    case invalidAmount
    case emptyTitle
    case invalidBudget

    var errorDescription: String? {
        switch self {
        case .accountNotFound: "The selected account no longer exists."
        case .invalidAmount: "Enter an amount greater than zero."
        case .emptyTitle: "Enter a title for the transaction."
        case .invalidBudget: "Enter a monthly budget greater than zero."
        }
    }
}

extension Array where Element == Account {
    func totalBalance(currencyCode: String = "USD") -> Money {
        let total = reduce(Decimal.zero) { $0 + $1.balance.amount }
        return Money(total, currencyCode: currencyCode)
    }
}
