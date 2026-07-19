import Foundation
import SwiftData

@MainActor
final class SwiftDataFinanceRepository: FinanceRepository {
    private let context: ModelContext

    init(modelContext: ModelContext) {
        context = modelContext
    }

    func fetchAccounts() throws -> [Account] {
        try context.fetch(FetchDescriptor<AccountRecord>())
            .sorted { $0.createdAt < $1.createdAt }
            .map(\.domainModel)
    }

    func fetchCategories() throws -> [SpendingCategory] {
        try context.fetch(FetchDescriptor<CategoryRecord>())
            .map(\.domainModel)
            .sorted { $0.name < $1.name }
    }

    func fetchTransactions() throws -> [FinancialTransaction] {
        try context.fetch(FetchDescriptor<TransactionRecord>())
            .map(\.domainModel)
            .sorted { $0.date > $1.date }
    }

    func fetchBudgets() throws -> [Budget] {
        try context.fetch(FetchDescriptor<BudgetRecord>())
            .map(\.domainModel)
    }

    func createAccount(_ draft: AccountDraft) throws {
        let cleanName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { throw FinanceRepositoryError.emptyTitle }
        let account = Account(
            name: cleanName,
            kind: draft.kind,
            balance: draft.openingBalance,
            iconName: draft.iconName,
            tintHex: draft.tintHex
        )
        context.insert(AccountRecord(account: account))
        try context.save()
    }

    func createTransaction(_ draft: TransactionDraft) throws {
        let cleanTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { throw FinanceRepositoryError.emptyTitle }
        guard draft.amount.amount > 0 else { throw FinanceRepositoryError.invalidAmount }
        guard let account = try accountRecord(id: draft.accountID) else {
            throw FinanceRepositoryError.accountNotFound
        }

        let transaction = FinancialTransaction(
            accountID: draft.accountID,
            categoryID: draft.categoryID,
            title: cleanTitle,
            amount: draft.amount,
            kind: draft.kind,
            date: draft.date,
            note: draft.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        context.insert(TransactionRecord(transaction: transaction))
        apply(transaction, to: account, reversing: false)
        try context.save()
    }

    func deleteTransaction(id: UUID) throws {
        var descriptor = FetchDescriptor<TransactionRecord>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else { return }
        if let account = try accountRecord(id: record.accountID) {
            apply(record.domainModel, to: account, reversing: true)
        }
        context.delete(record)
        try context.save()
    }

    func upsertBudget(_ draft: BudgetDraft) throws {
        guard draft.monthlyLimit.amount > 0 else { throw FinanceRepositoryError.invalidBudget }
        let categoryID = draft.categoryID
        var descriptor = FetchDescriptor<BudgetRecord>(
            predicate: #Predicate { $0.categoryID == categoryID }
        )
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.limitAmount = draft.monthlyLimit.amount
            existing.currencyCode = draft.monthlyLimit.currencyCode
        } else {
            context.insert(
                BudgetRecord(
                    budget: Budget(
                        categoryID: draft.categoryID,
                        monthlyLimit: draft.monthlyLimit
                    )
                )
            )
        }
        try context.save()
    }

    func seedIfNeeded() throws {
        guard try context.fetch(FetchDescriptor<AccountRecord>()).isEmpty else { return }

        let food = SpendingCategory(name: "Food", iconName: "fork.knife", tintHex: "#E17055")
        let salary = SpendingCategory(name: "Salary", iconName: "briefcase.fill", tintHex: "#00B894")
        let transport = SpendingCategory(name: "Transport", iconName: "car.fill", tintHex: "#0984E3")
        let shopping = SpendingCategory(name: "Shopping", iconName: "bag.fill", tintHex: "#6C5CE7")
        [food, salary, transport, shopping].forEach { context.insert(CategoryRecord(category: $0)) }

        [
            Budget(categoryID: food.id, monthlyLimit: Money(600)),
            Budget(categoryID: transport.id, monthlyLimit: Money(180)),
            Budget(categoryID: shopping.id, monthlyLimit: Money(400))
        ].forEach { context.insert(BudgetRecord(budget: $0)) }

        let everyday = Account(
            name: "Everyday",
            kind: .checking,
            balance: Money(Decimal(string: "4280.45")!),
            iconName: "building.columns.fill",
            tintHex: "#6C5CE7"
        )
        let savings = Account(
            name: "Savings",
            kind: .savings,
            balance: Money(12_750),
            iconName: "leaf.fill",
            tintHex: "#00B894"
        )
        let cash = Account(
            name: "Cash",
            kind: .cash,
            balance: Money(320),
            iconName: "banknote.fill",
            tintHex: "#0984E3"
        )
        [everyday, savings, cash].enumerated().forEach { index, account in
            context.insert(AccountRecord(account: account, createdAt: .now.addingTimeInterval(Double(index))))
        }

        let samples = [
            FinancialTransaction(
                accountID: everyday.id,
                categoryID: salary.id,
                title: "Monthly salary",
                amount: Money(5_840),
                kind: .income,
                date: .now.addingTimeInterval(-86_400 * 3)
            ),
            FinancialTransaction(
                accountID: everyday.id,
                categoryID: food.id,
                title: "Grocery market",
                amount: Money(Decimal(string: "86.40")!),
                kind: .expense,
                date: .now.addingTimeInterval(-86_400)
            ),
            FinancialTransaction(
                accountID: everyday.id,
                categoryID: transport.id,
                title: "City transport",
                amount: Money(24),
                kind: .expense,
                date: .now.addingTimeInterval(-3_600 * 8)
            ),
            FinancialTransaction(
                accountID: everyday.id,
                categoryID: shopping.id,
                title: "Running shoes",
                amount: Money(Decimal(string: "129.90")!),
                kind: .expense,
                date: .now.addingTimeInterval(-86_400 * 5)
            ),
            FinancialTransaction(
                accountID: everyday.id,
                categoryID: food.id,
                title: "Coffee with friends",
                amount: Money(Decimal(string: "18.50")!),
                kind: .expense,
                date: .now.addingTimeInterval(-86_400 * 3)
            ),
            FinancialTransaction(
                accountID: cash.id,
                categoryID: food.id,
                title: "Weekend lunch",
                amount: Money(Decimal(string: "42.80")!),
                kind: .expense,
                date: .now.addingTimeInterval(-86_400 * 6)
            )
        ]
        samples.forEach { context.insert(TransactionRecord(transaction: $0)) }
        try context.save()
    }

    private func accountRecord(id: UUID) throws -> AccountRecord? {
        var descriptor = FetchDescriptor<AccountRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func apply(_ transaction: FinancialTransaction, to account: AccountRecord, reversing: Bool) {
        let direction: Decimal = reversing ? -1 : 1
        switch transaction.kind {
        case .income:
            account.balanceAmount += transaction.amount.amount * direction
        case .expense:
            account.balanceAmount -= transaction.amount.amount * direction
        case .transfer:
            break
        }
    }
}
