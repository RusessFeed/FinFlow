import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        NavigationStack {
            List {
                Section("Preferences") {
                    Label("USD · US Dollar", systemImage: "dollarsign.circle")
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                }

                Section("Development") {
                    Button("Show onboarding again") {
                        container.resetOnboarding()
                    }
                }

                Section {
                    Text("FinFlow Foundation · 1.0")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
        }
    }
}
