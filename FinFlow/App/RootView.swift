import SwiftUI

struct RootView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        Group {
            if container.hasCompletedOnboarding {
                MainTabView()
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: container.hasCompletedOnboarding)
        .task {
            await container.refreshExchangeRates()
        }
    }
}

private struct MainTabView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        TabView(selection: $container.selectedTab) {
            OverviewView()
                .tag(AppTab.overview)
                .tabItem { Label(AppTab.overview.title, systemImage: AppTab.overview.systemImage) }

            ActivityView()
                .tag(AppTab.activity)
                .tabItem { Label(AppTab.activity.title, systemImage: AppTab.activity.systemImage) }

            AccountsView()
                .tag(AppTab.accounts)
                .tabItem { Label(AppTab.accounts.title, systemImage: AppTab.accounts.systemImage) }

            ProfileView()
                .tag(AppTab.profile)
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage) }
        }
    }
}
