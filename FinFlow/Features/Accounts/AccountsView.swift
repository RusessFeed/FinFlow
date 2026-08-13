import SwiftUI

struct AccountsView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var showingAddAccount = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Net worth")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(container.accounts.totalBalance().formatted())
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    }
                    .padding(.vertical, 8)
                }

                Section("Accounts") {
                    ForEach(container.accounts) { account in
                        AccountListRow(account: account)
                    }
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddAccount = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add account")
                }
            }
            .sheet(isPresented: $showingAddAccount) {
                AddAccountView()
            }
        }
    }
}

private struct AccountListRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: account.iconName)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color(hex: account.tintHex), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(.headline)
                Text(account.kind.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(account.balance.formatted())
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct AddAccountView: View {
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind: Account.Kind = .checking
    @State private var balance = ""
    @State private var errorMessage: String?

    private var parsedBalance: Decimal? {
        Decimal(string: balance.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account details") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $kind) {
                        ForEach(Account.Kind.allCases, id: \.self) { kind in
                            Text(kind.rawValue.capitalized).tag(kind)
                        }
                    }
                    TextField("Opening balance", text: $balance)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Label("Balances are stored locally on this device.", systemImage: "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || parsedBalance == nil)
                }
            }
            .alert("Could not add account", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func save() {
        guard let parsedBalance else { return }
        let style = AccountStyle.style(for: kind)
        do {
            try container.addAccount(
                AccountDraft(
                    name: name,
                    kind: kind,
                    openingBalance: Money(parsedBalance),
                    iconName: style.icon,
                    tintHex: style.tintHex
                )
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private enum AccountStyle {
    static func style(for kind: Account.Kind) -> (icon: String, tintHex: String) {
        switch kind {
        case .checking: ("building.columns.fill", "#6C5CE7")
        case .savings: ("leaf.fill", "#00B894")
        case .cash: ("banknote.fill", "#0984E3")
        case .credit: ("creditcard.fill", "#E17055")
        }
    }
}
