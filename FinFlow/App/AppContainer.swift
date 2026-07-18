import Foundation

@MainActor
final class AppContainer: ObservableObject {
    @Published var selectedTab: AppTab = .overview
    @Published private(set) var hasCompletedOnboarding: Bool

    let accountRepository: AccountRepository
    private let preferences: PreferencesStore

    init(
        accountRepository: AccountRepository,
        preferences: PreferencesStore
    ) {
        self.accountRepository = accountRepository
        self.preferences = preferences
        hasCompletedOnboarding = preferences.bool(forKey: PreferenceKey.onboardingCompleted)
    }

    func completeOnboarding() {
        preferences.set(true, forKey: PreferenceKey.onboardingCompleted)
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        preferences.set(false, forKey: PreferenceKey.onboardingCompleted)
        hasCompletedOnboarding = false
    }

    static func live() -> AppContainer {
        AppContainer(
            accountRepository: PreviewAccountRepository(),
            preferences: UserDefaultsPreferences()
        )
    }
}

enum PreferenceKey {
    static let onboardingCompleted = "finflow.onboarding.completed"
}
