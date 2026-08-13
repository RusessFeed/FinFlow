import Charts
import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var showingBudgets = false

    private var monthInterval: DateInterval {
        FinancialAnalytics.monthInterval(containing: .now)
    }

    private var summary: FinancialSummary {
        FinancialAnalytics.summary(transactions: container.transactions, in: monthInterval)
    }

    private var dailySpending: [DailySpendingPoint] {
        FinancialAnalytics.dailySpending(
            transactions: container.transactions,
            endingAt: .now,
            days: 7
        )
    }

    private var categorySpending: [CategorySpending] {
        FinancialAnalytics.categorySpending(
            transactions: container.transactions,
            in: monthInterval
        )
    }

    private var insights: [FinancialInsight] {
        FinancialInsightEngine.insights(
            transactions: container.transactions,
            budgets: container.budgets,
            categories: container.categories,
            in: monthInterval
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FFLayout.medium) {
                    BalanceCard(
                        balance: container.displayMoney(container.accounts.totalBalance()),
                        cashFlow: container.displayMoney(Money(summary.cashFlow))
                    )

                    HStack(spacing: FFLayout.medium) {
                        MetricCard(
                            title: "Income",
                            value: container.displayMoney(Money(summary.income)).formatted(),
                            color: FFColor.positive
                        )
                        MetricCard(
                            title: "Spent",
                            value: container.displayMoney(Money(summary.spending)).formatted(),
                            color: FFColor.negative
                        )
                    }

                    InsightStripCard(insights: insights)

                    SpendingTrendCard(points: dailySpending)

                    BudgetOverviewCard(
                        budgets: container.budgets,
                        categories: container.categories,
                        spending: categorySpending,
                        onEdit: { showingBudgets = true }
                    )

                    CategoryBreakdownCard(
                        spending: categorySpending,
                        categories: container.categories
                    )

                    AccountsSummaryCard(accounts: container.accounts)
                }
                .padding(FFLayout.medium)
            }
            .background(FFColor.canvas)
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {} label: { Image(systemName: "bell") }
                        .accessibilityLabel("Notifications")
                }
            }
            .sheet(isPresented: $showingBudgets) {
                ManageBudgetsView()
            }
        }
    }
}

private struct InsightStripCard: View {
    let insights: [FinancialInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: FFLayout.small) {
            Text("Smart insights")
                .font(.headline)
                .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(insights) { insight in
                        InsightTile(insight: insight)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

private struct InsightTile: View {
    let insight: FinancialInsight

    private var color: Color {
        switch insight.tone {
        case .positive: FFColor.positive
        case .warning: FFColor.warning
        case .attention: FFColor.negative
        case .neutral: FFColor.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FFLayout.small) {
            Image(systemName: insight.systemImage)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12), in: Circle())

            Text(insight.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(insight.message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(width: 230, alignment: .topLeading)
        .frame(minHeight: 150, alignment: .topLeading)
        .background(FFColor.card, in: RoundedRectangle(cornerRadius: FFLayout.cardRadius))
        .accessibilityElement(children: .combine)
    }
}

private struct BalanceCard: View {
    let balance: Money
    let cashFlow: Money

    var body: some View {
        VStack(alignment: .leading, spacing: FFLayout.medium) {
            Label("Total balance", systemImage: "sparkles")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Text(balance.formatted())
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            HStack {
                Text("Monthly cash flow")
                Spacer()
                Text(cashFlow.formatted())
                    .monospacedDigit()
            }
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
                Text(value)
                    .font(.headline)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
    }
}

private struct SpendingTrendCard: View {
    let points: [DailySpendingPoint]

    var body: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFLayout.medium) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Spending trend").font(.headline)
                    Text("Last 7 days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Chart(points) { point in
                    AreaMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Spending", point.amount.doubleValue)
                    )
                    .foregroundStyle(FFColor.accent.opacity(0.14).gradient)

                    LineMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Spending", point.amount.doubleValue)
                    )
                    .foregroundStyle(FFColor.accent)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Spending", point.amount.doubleValue)
                    )
                    .foregroundStyle(FFColor.accent)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 180)
                .accessibilityLabel("Spending over the last seven days")
            }
        }
    }
}

private struct BudgetOverviewCard: View {
    let budgets: [Budget]
    let categories: [SpendingCategory]
    let spending: [CategorySpending]
    let onEdit: () -> Void

    var body: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFLayout.medium) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Monthly budgets").font(.headline)
                        Text("Stay ahead of category limits")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(action: onEdit) {
                        Image(systemName: "slider.horizontal.3")
                            .frame(width: 36, height: 36)
                            .background(FFColor.accent.opacity(0.1), in: Circle())
                    }
                    .accessibilityLabel("Manage budgets")
                }

                ForEach(budgets) { budget in
                    if let category = categories.first(where: { $0.id == budget.categoryID }) {
                        let spent = spending.first(where: { $0.categoryID == budget.categoryID })?.amount ?? 0
                        BudgetProgressRow(category: category, spent: spent, limit: budget.monthlyLimit.amount)
                    }
                }
            }
        }
    }
}

private struct BudgetProgressRow: View {
    let category: SpendingCategory
    let spent: Decimal
    let limit: Decimal

    private var ratio: Double {
        guard limit > 0 else { return 0 }
        return NSDecimalNumber(decimal: spent / limit).doubleValue
    }

    private var progressColor: Color {
        if ratio >= 1 { return FFColor.negative }
        if ratio >= 0.8 { return FFColor.warning }
        return Color(hex: category.tintHex)
    }

    var body: some View {
        VStack(spacing: FFLayout.small) {
            HStack {
                Label(category.name, systemImage: category.iconName)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Money(spent).formatted()) / \(Money(limit).formatted())")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(ratio, 1))
                .tint(progressColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(Int(ratio * 100)) percent used")
    }
}

private struct CategoryBreakdownCard: View {
    let spending: [CategorySpending]
    let categories: [SpendingCategory]

    var body: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFLayout.medium) {
                Text("Spending by category").font(.headline)

                if spending.isEmpty {
                    Text("Add expenses to see a category breakdown.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Chart(spending) { item in
                        let category = categories.first { $0.id == item.categoryID }
                        BarMark(
                            x: .value("Amount", item.amount.doubleValue),
                            y: .value("Category", category?.name ?? "Other")
                        )
                        .foregroundStyle(Color(hex: category?.tintHex ?? "#636E72"))
                        .cornerRadius(6)
                        .annotation(position: .trailing) {
                            Text(Money(item.amount).formatted())
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .chartXAxis(.hidden)
                    .frame(height: CGFloat(max(spending.count, 1)) * 48)
                    .accessibilityLabel("Monthly spending grouped by category")
                }
            }
        }
    }
}

private struct AccountsSummaryCard: View {
    let accounts: [Account]

    var body: some View {
        FFCard {
            VStack(alignment: .leading, spacing: FFLayout.medium) {
                Text("Your accounts").font(.headline)
                ForEach(accounts) { account in
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
        }
    }
}

private struct ManageBudgetsView: View {
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss
    @State private var categoryID: UUID?
    @State private var limit = ""
    @State private var errorMessage: String?

    private var parsedLimit: Decimal? {
        guard let value = Decimal(string: limit.replacingOccurrences(of: ",", with: ".")), value > 0 else {
            return nil
        }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category budget") {
                    Picker("Category", selection: $categoryID) {
                        Text("Select category").tag(UUID?.none)
                        ForEach(container.categories) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                    TextField("Monthly limit", text: $limit)
                        .keyboardType(.decimalPad)
                }

                Section("Current limits") {
                    ForEach(container.budgets) { budget in
                        if let category = container.category(id: budget.categoryID) {
                            LabeledContent(category.name, value: budget.monthlyLimit.formatted())
                        }
                    }
                }
            }
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(categoryID == nil || parsedLimit == nil)
                }
            }
            .onChange(of: categoryID) { _, newValue in
                guard let newValue,
                      let budget = container.budgets.first(where: { $0.categoryID == newValue }) else {
                    limit = ""
                    return
                }
                limit = NSDecimalNumber(decimal: budget.monthlyLimit.amount).stringValue
            }
            .alert("Could not save budget", isPresented: errorBinding) {
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
        guard let categoryID, let parsedLimit else { return }
        do {
            try container.setBudget(
                BudgetDraft(categoryID: categoryID, monthlyLimit: Money(parsedLimit))
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private extension Decimal {
    var doubleValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}
