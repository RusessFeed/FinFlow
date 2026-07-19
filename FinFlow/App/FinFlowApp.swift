import SwiftUI
import SwiftData

@main
struct FinFlowApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var container: AppContainer

    @MainActor
    init() {
        do {
            let modelContainer = try ModelContainer(
                for: AccountRecord.self,
                CategoryRecord.self,
                TransactionRecord.self,
                BudgetRecord.self
            )
            let repository = SwiftDataFinanceRepository(modelContext: modelContainer.mainContext)
            try repository.seedIfNeeded()
            self.modelContainer = modelContainer
            _container = StateObject(
                wrappedValue: AppContainer(
                    financeRepository: repository,
                    preferences: UserDefaultsPreferences()
                )
            )
        } catch {
            fatalError("Unable to initialize FinFlow storage: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .tint(FFColor.accent)
        }
        .modelContainer(modelContainer)
    }
}
