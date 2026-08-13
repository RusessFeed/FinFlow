import Foundation

struct FinancialInsight: Identifiable, Equatable {
    enum Tone: Equatable {
        case positive
        case warning
        case attention
        case neutral
    }

    let id: String
    let title: String
    let message: String
    let systemImage: String
    let tone: Tone
}

struct RecurringExpense: Identifiable, Equatable {
    var id: String { normalizedTitle }
    let normalizedTitle: String
    let title: String
    let averageAmount: Decimal
    let occurrenceCount: Int
    let averageIntervalDays: Int
}

enum FinancialInsightEngine {
    static func insights(
        transactions: [FinancialTransaction],
        budgets: [Budget],
        categories: [SpendingCategory],
        in interval: DateInterval,
        calendar: Calendar = .current
    ) -> [FinancialInsight] {
        var results: [FinancialInsight] = []
        let categorySpending = FinancialAnalytics.categorySpending(transactions: transactions, in: interval)
        let summary = FinancialAnalytics.summary(transactions: transactions, in: interval)

        if let budgetInsight = budgetWarning(
            spending: categorySpending,
            budgets: budgets,
            categories: categories
        ) {
            results.append(budgetInsight)
        }

        if let topCategory = categorySpending.first,
           let category = categories.first(where: { $0.id == topCategory.categoryID }) {
            results.append(
                FinancialInsight(
                    id: "top-category-\(category.id)",
                    title: "\(category.name) leads spending",
                    message: "\(Money(topCategory.amount).formatted()) spent this month.",
                    systemImage: category.iconName,
                    tone: .neutral
                )
            )
        }

        if let recurring = recurringExpenses(transactions: transactions, calendar: calendar).first {
            results.append(
                FinancialInsight(
                    id: "recurring-\(recurring.id)",
                    title: "Recurring expense spotted",
                    message: "\(recurring.title) appears \(recurring.occurrenceCount) times, about every \(recurring.averageIntervalDays) days.",
                    systemImage: "repeat",
                    tone: .attention
                )
            )
        }

        if summary.cashFlow > 0 {
            results.append(
                FinancialInsight(
                    id: "positive-cash-flow",
                    title: "Positive cash flow",
                    message: "\(Money(summary.cashFlow).formatted()) left after this month's spending.",
                    systemImage: "arrow.up.right.circle.fill",
                    tone: .positive
                )
            )
        }

        if results.isEmpty {
            results.append(
                FinancialInsight(
                    id: "keep-tracking",
                    title: "Keep tracking",
                    message: "Add a few more transactions to unlock smarter insights.",
                    systemImage: "sparkles",
                    tone: .neutral
                )
            )
        }
        return Array(results.prefix(4))
    }

    static func recurringExpenses(
        transactions: [FinancialTransaction],
        calendar: Calendar = .current
    ) -> [RecurringExpense] {
        let grouped = Dictionary(grouping: transactions.filter { $0.kind == .expense }) {
            normalizeTitle($0.title)
        }

        return grouped.compactMap { normalizedTitle, transactions in
            let sorted = transactions.sorted { $0.date < $1.date }
            guard sorted.count >= 2 else { return nil }
            let gaps = zip(sorted, sorted.dropFirst()).map {
                calendar.dateComponents([.day], from: $0.date, to: $1.date).day ?? 0
            }
            let positiveGaps = gaps.filter { $0 > 0 }
            guard let averageGap = average(positiveGaps), averageGap >= 6 else { return nil }
            let averageAmount = sorted.reduce(Decimal.zero) { $0 + $1.amount.amount } / Decimal(sorted.count)
            return RecurringExpense(
                normalizedTitle: normalizedTitle,
                title: sorted[0].title,
                averageAmount: averageAmount,
                occurrenceCount: sorted.count,
                averageIntervalDays: averageGap
            )
        }
        .sorted { $0.occurrenceCount > $1.occurrenceCount }
    }

    private static func budgetWarning(
        spending: [CategorySpending],
        budgets: [Budget],
        categories: [SpendingCategory]
    ) -> FinancialInsight? {
        let usages = budgets.compactMap { budget -> (Budget, SpendingCategory, Decimal, Double)? in
            guard let category = categories.first(where: { $0.id == budget.categoryID }) else { return nil }
            let spent = spending.first(where: { $0.categoryID == budget.categoryID })?.amount ?? 0
            guard budget.monthlyLimit.amount > 0 else { return nil }
            let ratio = NSDecimalNumber(decimal: spent / budget.monthlyLimit.amount).doubleValue
            return (budget, category, spent, ratio)
        }
        guard let highest = usages.sorted(by: { $0.3 > $1.3 }).first, highest.3 >= 0.8 else {
            return nil
        }
        let percentage = Int((highest.3 * 100).rounded())
        let tone: FinancialInsight.Tone = highest.3 >= 1 ? .warning : .attention
        return FinancialInsight(
            id: "budget-\(highest.1.id)",
            title: "\(highest.1.name) budget is \(percentage)% used",
            message: "\(Money(highest.2).formatted()) of \(highest.0.monthlyLimit.formatted()) spent.",
            systemImage: "gauge.with.dots.needle.bottom.100percent",
            tone: tone
        )
    }

    private static func normalizeTitle(_ title: String) -> String {
        title.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func average(_ values: [Int]) -> Int? {
        guard !values.isEmpty else { return nil }
        return Int((Double(values.reduce(0, +)) / Double(values.count)).rounded())
    }
}
