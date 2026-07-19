import SwiftData
import XCTest
@testable import FinFlow

@MainActor
final class FinanceRepositoryTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var repository: SwiftDataFinanceRepository!

    override func setUpWithError() throws {
        let schema = Schema([
            AccountRecord.self,
            CategoryRecord.self,
            TransactionRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        repository = SwiftDataFinanceRepository(modelContext: modelContainer.mainContext)
    }

    override func tearDownWithError() throws {
        repository = nil
        modelContainer = nil
    }

    func testCreatingAccountPersistsItsBalance() throws {
        try repository.createAccount(
            AccountDraft(
                name: "Travel",
                kind: .savings,
                openingBalance: Money(1_500),
                iconName: "airplane",
                tintHex: "#0984E3"
            )
        )

        let account = try XCTUnwrap(repository.fetchAccounts().first)
        XCTAssertEqual(account.name, "Travel")
        XCTAssertEqual(account.balance, Money(1_500))
    }

    func testExpenseUpdatesBalanceAndDeletingItRestoresBalance() throws {
        try repository.createAccount(
            AccountDraft(
                name: "Everyday",
                kind: .checking,
                openingBalance: Money(500),
                iconName: "building.columns.fill",
                tintHex: "#6C5CE7"
            )
        )
        let account = try XCTUnwrap(repository.fetchAccounts().first)

        try repository.createTransaction(
            TransactionDraft(
                accountID: account.id,
                categoryID: nil,
                title: "Lunch",
                amount: Money(25),
                kind: .expense,
                date: .now,
                note: nil
            )
        )

        XCTAssertEqual(try repository.fetchAccounts().first?.balance, Money(475))
        let transaction = try XCTUnwrap(repository.fetchTransactions().first)

        try repository.deleteTransaction(id: transaction.id)

        XCTAssertTrue(try repository.fetchTransactions().isEmpty)
        XCTAssertEqual(try repository.fetchAccounts().first?.balance, Money(500))
    }

    func testRejectsNonPositiveTransactionAmount() throws {
        try repository.createAccount(
            AccountDraft(
                name: "Cash",
                kind: .cash,
                openingBalance: Money(100),
                iconName: "banknote.fill",
                tintHex: "#0984E3"
            )
        )
        let account = try XCTUnwrap(repository.fetchAccounts().first)

        XCTAssertThrowsError(
            try repository.createTransaction(
                TransactionDraft(
                    accountID: account.id,
                    categoryID: nil,
                    title: "Invalid",
                    amount: Money(0),
                    kind: .expense,
                    date: .now,
                    note: nil
                )
            )
        )
    }
}
