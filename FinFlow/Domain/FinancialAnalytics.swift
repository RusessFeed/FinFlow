import Foundation

struct FinancialSummary: Equatable {
    let income: Decimal
    let spending: Decimal

    var cashFlow: Decimal { income - spending }
}

struct DailySpendingPoint: Identifiable, Equatable {
    var id: Date { date }
    let date: Date
    let amount: Decimal
}

struct CategorySpending: Identifiable, Equatable {
    var id: UUID { categoryID }
    let categoryID: UUID
    let amount: Decimal
}

enum FinancialAnalytics {
    static func summary(
        transactions: [FinancialTransaction],
        in interval: DateInterval
    ) -> FinancialSummary {
        let included = transactions.filter { interval.contains($0.date) }
        let income = included
            .filter { $0.kind == .income }
            .reduce(Decimal.zero) { $0 + $1.amount.amount }
        let spending = included
            .filter { $0.kind == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount.amount }
        return FinancialSummary(income: income, spending: spending)
    }

    static func dailySpending(
        transactions: [FinancialTransaction],
        endingAt endDate: Date,
        days: Int,
        calendar: Calendar = .current
    ) -> [DailySpendingPoint] {
        guard days > 0 else { return [] }
        let end = calendar.startOfDay(for: endDate)
        return (0..<days).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: end),
                  let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { return nil }
            let amount = transactions
                .filter { $0.kind == .expense && $0.date >= date && $0.date < nextDate }
                .reduce(Decimal.zero) { $0 + $1.amount.amount }
            return DailySpendingPoint(date: date, amount: amount)
        }
    }

    static func categorySpending(
        transactions: [FinancialTransaction],
        in interval: DateInterval
    ) -> [CategorySpending] {
        let grouped = Dictionary(grouping: transactions.filter {
            $0.kind == .expense && interval.contains($0.date) && $0.categoryID != nil
        }) { $0.categoryID! }
        return grouped.map { categoryID, transactions in
            CategorySpending(
                categoryID: categoryID,
                amount: transactions.reduce(Decimal.zero) { $0 + $1.amount.amount }
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    static func monthInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        calendar.dateInterval(of: .month, for: date) ?? DateInterval(start: date, duration: 0)
    }
}
