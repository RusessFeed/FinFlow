import XCTest
@testable import FinFlow

final class FinancialAnalyticsTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testSummarySeparatesIncomeAndSpending() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let interval = DateInterval(start: start, duration: 86_400)
        let accountID = UUID()
        let transactions = [
            transaction(accountID: accountID, amount: 1_000, kind: .income, date: start.addingTimeInterval(100)),
            transaction(accountID: accountID, amount: 240, kind: .expense, date: start.addingTimeInterval(200)),
            transaction(accountID: accountID, amount: 80, kind: .expense, date: interval.end.addingTimeInterval(1))
        ]

        let summary = FinancialAnalytics.summary(transactions: transactions, in: interval)

        XCTAssertEqual(summary.income, 1_000)
        XCTAssertEqual(summary.spending, 240)
        XCTAssertEqual(summary.cashFlow, 760)
    }

    func testDailySpendingIncludesZeroValueDays() throws {
        let endDate = Date(timeIntervalSince1970: 1_728_000)
        let today = calendar.startOfDay(for: endDate)
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let accountID = UUID()
        let transactions = [
            transaction(accountID: accountID, amount: 35, kind: .expense, date: yesterday.addingTimeInterval(100))
        ]

        let points = FinancialAnalytics.dailySpending(
            transactions: transactions,
            endingAt: endDate,
            days: 3,
            calendar: calendar
        )

        XCTAssertEqual(points.count, 3)
        XCTAssertEqual(points.map(\.amount), [0, 35, 0])
    }

    func testCategorySpendingIsSortedByAmount() {
        let start = Date(timeIntervalSince1970: 2_000_000)
        let interval = DateInterval(start: start, duration: 86_400)
        let accountID = UUID()
        let foodID = UUID()
        let travelID = UUID()
        let transactions = [
            transaction(accountID: accountID, categoryID: foodID, amount: 40, kind: .expense, date: start),
            transaction(accountID: accountID, categoryID: travelID, amount: 120, kind: .expense, date: start)
        ]

        let result = FinancialAnalytics.categorySpending(transactions: transactions, in: interval)

        XCTAssertEqual(result.map(\.categoryID), [travelID, foodID])
        XCTAssertEqual(result.map(\.amount), [120, 40])
    }

    private func transaction(
        accountID: UUID,
        categoryID: UUID? = nil,
        amount: Decimal,
        kind: FinancialTransaction.Kind,
        date: Date
    ) -> FinancialTransaction {
        FinancialTransaction(
            accountID: accountID,
            categoryID: categoryID,
            title: "Test",
            amount: Money(amount),
            kind: kind,
            date: date
        )
    }
}
