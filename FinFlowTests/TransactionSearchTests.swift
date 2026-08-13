import XCTest
@testable import FinFlow

final class TransactionSearchTests: XCTestCase {
    func testSearchMatchesCategoryAndAccountNames() {
        let accountID = UUID()
        let categoryID = UUID()
        let account = Account(
            id: accountID,
            name: "Everyday",
            kind: .checking,
            balance: Money(500),
            iconName: "creditcard",
            tintHex: "#6C5CE7"
        )
        let category = SpendingCategory(
            id: categoryID,
            name: "Groceries",
            iconName: "cart.fill",
            tintHex: "#00B894"
        )
        let transactions = [
            transaction(accountID: accountID, categoryID: categoryID, title: "Market", kind: .expense),
            transaction(accountID: UUID(), categoryID: nil, title: "Salary", kind: .income)
        ]

        let result = TransactionSearch.filter(
            transactions: transactions,
            accounts: [account],
            categories: [category],
            filter: TransactionSearchFilter(query: "groceries")
        )

        XCTAssertEqual(result.map(\.title), ["Market"])
    }

    func testFiltersByKindAndCategory() {
        let foodID = UUID()
        let travelID = UUID()
        let transactions = [
            transaction(categoryID: foodID, title: "Lunch", kind: .expense),
            transaction(categoryID: travelID, title: "Taxi", kind: .expense),
            transaction(categoryID: foodID, title: "Refund", kind: .income)
        ]

        let result = TransactionSearch.filter(
            transactions: transactions,
            accounts: [],
            categories: [],
            filter: TransactionSearchFilter(kind: .expenses, categoryID: foodID)
        )

        XCTAssertEqual(result.map(\.title), ["Lunch"])
    }

    private func transaction(
        accountID: UUID = UUID(),
        categoryID: UUID? = nil,
        title: String,
        kind: FinancialTransaction.Kind
    ) -> FinancialTransaction {
        FinancialTransaction(
            accountID: accountID,
            categoryID: categoryID,
            title: title,
            amount: Money(25),
            kind: kind,
            date: Date(timeIntervalSince1970: TimeInterval(title.hashValue.magnitude % 1_000))
        )
    }
}
