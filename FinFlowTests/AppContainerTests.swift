import XCTest
@testable import FinFlow

@MainActor
final class AppContainerTests: XCTestCase {
    func testCompletingOnboardingPersistsState() {
        let preferences = InMemoryPreferences()
        let container = AppContainer(
            financeRepository: StubFinanceRepository(),
            preferences: preferences
        )

        container.completeOnboarding()

        XCTAssertTrue(container.hasCompletedOnboarding)
        XCTAssertTrue(preferences.bool(forKey: PreferenceKey.onboardingCompleted))
    }

    func testContainerRestoresPersistedOnboardingState() {
        let preferences = InMemoryPreferences(
            values: [PreferenceKey.onboardingCompleted: true]
        )

        let container = AppContainer(
            financeRepository: StubFinanceRepository(),
            preferences: preferences
        )

        XCTAssertTrue(container.hasCompletedOnboarding)
    }

    func testContainerRefreshesAfterAddingAccount() throws {
        let repository = StubFinanceRepository()
        let container = AppContainer(
            financeRepository: repository,
            preferences: InMemoryPreferences()
        )

        try container.addAccount(
            AccountDraft(
                name: "Travel",
                kind: .savings,
                openingBalance: Money(800),
                iconName: "airplane",
                tintHex: "#0984E3"
            )
        )

        XCTAssertEqual(container.accounts.first?.name, "Travel")
    }

    func testPreferredCurrencyPersistsAndConvertsBalance() async {
        let preferences = InMemoryPreferences()
        let rates = ExchangeRateSnapshot(
            baseCurrency: "USD",
            rates: ["EUR": Decimal(string: "0.8")!],
            marketDate: "2026-07-18",
            fetchedAt: .now
        )
        let container = AppContainer(
            financeRepository: StubFinanceRepository(),
            preferences: preferences,
            currencyRateService: StubCurrencyRateService(snapshot: rates)
        )

        container.setPreferredCurrency("EUR")
        await container.refreshExchangeRates()

        XCTAssertEqual(preferences.string(forKey: PreferenceKey.preferredCurrency), "EUR")
        XCTAssertEqual(container.displayMoney(Money(100)), Money(80, currencyCode: "EUR"))
    }
}

private struct StubCurrencyRateService: CurrencyRateService {
    let snapshot: ExchangeRateSnapshot

    func rates(baseCurrency: String) async throws -> ExchangeRateSnapshot {
        snapshot
    }
}

@MainActor
private final class StubFinanceRepository: FinanceRepository {
    private var accounts: [Account] = []
    private var transactions: [FinancialTransaction] = []

    func fetchAccounts() throws -> [Account] { accounts }
    func fetchCategories() throws -> [SpendingCategory] { [] }
    func fetchTransactions() throws -> [FinancialTransaction] { transactions }
    func fetchBudgets() throws -> [Budget] { [] }

    func createAccount(_ draft: AccountDraft) throws {
        accounts.append(
            Account(
                name: draft.name,
                kind: draft.kind,
                balance: draft.openingBalance,
                iconName: draft.iconName,
                tintHex: draft.tintHex
            )
        )
    }

    func createTransaction(_ draft: TransactionDraft) throws {
        transactions.append(
            FinancialTransaction(
                accountID: draft.accountID,
                categoryID: draft.categoryID,
                title: draft.title,
                amount: draft.amount,
                kind: draft.kind,
                date: draft.date,
                note: draft.note
            )
        )
    }

    func deleteTransaction(id: UUID) throws {
        transactions.removeAll { $0.id == id }
    }

    func upsertBudget(_ draft: BudgetDraft) throws {}
}
