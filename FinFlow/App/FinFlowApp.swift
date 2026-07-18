import SwiftUI

@main
struct FinFlowApp: App {
    @StateObject private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .tint(FFColor.accent)
        }
    }
}
