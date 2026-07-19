import Foundation

@MainActor
final class AppContainer: ObservableObject {
    @Published var selectedTab: AppTab = .overview
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var categories: [SpendingCategory] = []
    @Published private(set) var transactions: [FinancialTransaction] = []

    private let financeRepository: FinanceRepository
    private let preferences: PreferencesStore

    init(
        financeRepository: FinanceRepository,
        preferences: PreferencesStore
    ) {
        self.financeRepository = financeRepository
        self.preferences = preferences
        hasCompletedOnboarding = preferences.bool(forKey: PreferenceKey.onboardingCompleted)
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
    }
}

enum PreferenceKey {
    static let onboardingCompleted = "finflow.onboarding.completed"
}
