import XCTest
@testable import FinFlow

@MainActor
final class AppContainerTests: XCTestCase {
    func testCompletingOnboardingPersistsState() {
        let preferences = InMemoryPreferences()
        let container = AppContainer(
            accountRepository: PreviewAccountRepository(),
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
            accountRepository: PreviewAccountRepository(),
            preferences: preferences
        )

        XCTAssertTrue(container.hasCompletedOnboarding)
    }
}
