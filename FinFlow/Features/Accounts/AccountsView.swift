import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        NavigationStack {
            List(container.accountRepository.fetchAccounts()) { account in
                HStack(spacing: 12) {
                    Image(systemName: account.iconName)
                        .foregroundStyle(Color(hex: account.tintHex))
                        .frame(width: 34)
                    VStack(alignment: .leading) {
                        Text(account.name).font(.headline)
                        Text(account.kind.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(account.balance.formatted())
                        .font(.subheadline.monospacedDigit())
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("Accounts")
        }
    }
}
