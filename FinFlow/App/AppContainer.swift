import Foundation

@MainActor
final class AppContainer: ObservableObject {
    @Published var selectedTab: AppTab = .overview
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var categories: [SpendingCategory] = []
    @Published private(set) var transactions: [FinancialTransaction] = []
    @Published private(set) var budgets: [Budget] = []
    @Published private(set) var preferredCurrency: String
    @Published private(set) var exchangeRates: ExchangeRateSnapshot?
    @Published private(set) var isRefreshingRates = false
    @Published private(set) var rateErrorMessage: String?

    private let financeRepository: FinanceRepository
    private let preferences: PreferencesStore
    private let currencyRateService: CurrencyRateService

    init(
        financeRepository: FinanceRepository,
        preferences: PreferencesStore,
        currencyRateService: CurrencyRateService = UnavailableCurrencyRateService()
    ) {
        self.financeRepository = financeRepository
        self.preferences = preferences
        self.currencyRateService = currencyRateService
        hasCompletedOnboarding = preferences.bool(forKey: PreferenceKey.onboardingCompleted)
        preferredCurrency = preferences.string(forKey: PreferenceKey.preferredCurrency) ?? "USD"
        refresh()
    }

    func completeOnboarding() {
        preferences.set(true, forKey: PreferenceKey.onboardingCompleted)
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        preferences.set(false, forKey: PreferenceKey.onboardingCompleted)
        hasCompletedOnboarding = false
    }

    func addAccount(_ draft: AccountDraft) throws {
        try financeRepository.createAccount(draft)
        refresh()
    }

    func addTransaction(_ draft: TransactionDraft) throws {
        try financeRepository.createTransaction(draft)
        refresh()
    }

    func deleteTransaction(id: UUID) throws {
        try financeRepository.deleteTransaction(id: id)
        refresh()
    }

    func setBudget(_ draft: BudgetDraft) throws {
        try financeRepository.upsertBudget(draft)
        refresh()
    }

    func account(id: UUID) -> Account? {
        accounts.first { $0.id == id }
    }

    func category(id: UUID?) -> SpendingCategory? {
        categories.first { $0.id == id }
    }

    func refresh() {
        accounts = (try? financeRepository.fetchAccounts()) ?? []
        categories = (try? financeRepository.fetchCategories()) ?? []
        transactions = (try? financeRepository.fetchTransactions()) ?? []
        budgets = (try? financeRepository.fetchBudgets()) ?? []
    }

    func setPreferredCurrency(_ currencyCode: String) {
        preferredCurrency = currencyCode
        preferences.set(currencyCode, forKey: PreferenceKey.preferredCurrency)
    }

    func refreshExchangeRates() async {
        guard !isRefreshingRates else { return }
        isRefreshingRates = true
        rateErrorMessage = nil
        do {
            exchangeRates = try await currencyRateService.rates(baseCurrency: "USD")
        } catch {
            rateErrorMessage = error.localizedDescription
        }
        isRefreshingRates = false
    }

    func displayMoney(_ money: Money) -> Money {
        guard preferredCurrency != money.currencyCode,
              let converted = exchangeRates?.convert(money, to: preferredCurrency) else {
            return money
        }
        return converted
    }
}

enum PreferenceKey {
    static let onboardingCompleted = "finflow.onboarding.completed"
    static let preferredCurrency = "finflow.preferred-currency"
}
