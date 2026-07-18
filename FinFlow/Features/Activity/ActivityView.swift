import SwiftUI

struct ActivityView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No transactions yet",
                systemImage: "arrow.left.arrow.right.circle",
                description: Text("Transactions will appear here in the next milestone.")
            )
            .navigationTitle("Activity")
        }
    }
}
