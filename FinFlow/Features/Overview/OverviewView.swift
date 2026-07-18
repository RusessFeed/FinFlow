import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var container: AppContainer

    private var accounts: [Account] {
        container.accountRepository.fetchAccounts()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FFLayout.medium) {
                    BalanceCard(balance: accounts.totalBalance())

                    HStack(spacing: FFLayout.medium) {
                        MetricCard(title: "Income", value: "$5,840", color: FFColor.positive)
                        MetricCard(title: "Spent", value: "$2,190", color: FFColor.negative)
                    }

                    FFCard {
                        VStack(alignment: .leading, spacing: FFLayout.medium) {
                            Text("Your accounts")
                                .font(.headline)
                            ForEach(accounts) { account in
                                AccountRow(account: account)
                            }
                        }
                    }
                }
                .padding(FFLayout.medium)
            }
            .background(FFColor.canvas)
            .navigationTitle("Good morning")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: {
                        Image(systemName: "bell")
                    }
                    .accessibilityLabel("Notifications")
                }
            }
        }
    }
}

private struct BalanceCard: View {
    let balance: Money

    var body: some View {
        VStack(alignment: .leading, spacing: FFLayout.medium) {
            Label("Total balance", systemImage: "sparkles")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Text(balance.formatted())
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text("+8.4% this month")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(FFLayout.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FFColor.accent.gradient, in: RoundedRectangle(cornerRadius: FFLayout.cardRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFLayout.small) {
                Circle().fill(color).frame(width: 10, height: 10)
                Text(title).font(.caption).foregroundStyle(FFColor.secondaryText)
                Text(value).font(.headline)
            }
        }
    }
}

private struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: account.iconName)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color(hex: account.tintHex), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(.subheadline.weight(.semibold))
                Text(account.kind.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(FFColor.secondaryText)
            }
            Spacer()
            Text(account.balance.formatted())
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }
}
