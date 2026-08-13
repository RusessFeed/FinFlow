import XCTest
@testable import FinFlow

final class FinancialInsightsTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testInsightsIncludeBudgetWarningWhenLimitIsNearlyUsed() {
        let categoryID = UUID()
        let category = SpendingCategory(
            id: categoryID,
            name: "Food",
            iconName: "fork.knife",
            tintHex: "#E17055"
        )
        let start = Date(timeIntervalSince1970: 1_000_000)
        let interval = DateInterval(start: start, duration: 86_400)

        let insights = FinancialInsightEngine.insights(
            transactions: [
                transaction(categoryID: categoryID, amount: 90, kind: .expense, date: start.addingTimeInterval(100))
            ],
            budgets: [
                Budget(categoryID: categoryID, monthlyLimit: Money(100))
            ],
            categories: [category],
            in: interval,
            calendar: calendar
        )

        XCTAssertEqual(insights.first?.id, "budget-\(categoryID)")
        XCTAssertEqual(insights.first?.tone, .attention)
    }

    func testRecurringExpenseDetectionUsesAverageInterval() throws {
        let first = Date(timeIntervalSince1970: 2_000_000)
        let second = try XCTUnwrap(calendar.date(byAdding: .day, value: 30, to: first))
        let third = try XCTUnwrap(calendar.date(byAdding: .day, value: 60, to: first))

        let recurring = FinancialInsightEngine.recurringExpenses(
            transactions: [
                transaction(title: "Netflix", amount: 12, kind: .expense, date: first),
                transaction(title: "netflix", amount: 12, kind: .expense, date: second),
                transaction(title: "NETFLIX", amount: 12, kind: .expense, date: third)
            ],
            calendar: calendar
        )

        XCTAssertEqual(recurring.first?.title, "Netflix")
        XCTAssertEqual(recurring.first?.occurrenceCount, 3)
        XCTAssertEqual(recurring.first?.averageIntervalDays, 30)
    }

    func testPositiveCashFlowCreatesInsight() {
        let start = Date(timeIntervalSince1970: 3_000_000)
        let interval = DateInterval(start: start, duration: 86_400)

        let insights = FinancialInsightEngine.insights(
            transactions: [
                transaction(amount: 500, kind: .income, date: start.addingTimeInterval(1)),
                transaction(amount: 100, kind: .expense, date: start.addingTimeInterval(2))
            ],
            budgets: [],
            categories: [],
            in: interval,
            calendar: calendar
        )

        XCTAssertTrue(insights.contains { $0.id == "positive-cash-flow" })
    }

    private func transaction(
        categoryID: UUID? = nil,
        title: String = "Test",
        amount: Decimal,
        kind: FinancialTransaction.Kind,
        date: Date
    ) -> FinancialTransaction {
        FinancialTransaction(
            accountID: UUID(),
            categoryID: categoryID,
            title: title,
            amount: Money(amount),
            kind: kind,
            date: date
        )
    }
}
