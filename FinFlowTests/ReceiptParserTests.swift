import XCTest
@testable import FinFlow

final class ReceiptParserTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testParsesMerchantTotalAndEuropeanDate() throws {
        let result = ReceiptParser.parse(
            lines: [
                "GREEN MARKET",
                "Fresh groceries",
                "18/07/2026 18:42",
                "Subtotal 82.40",
                "Tax 4.12",
                "TOTAL $86.52"
            ],
            calendar: calendar
        )

        XCTAssertEqual(result.merchant, "GREEN MARKET")
        XCTAssertEqual(result.total, Decimal(string: "86.52"))
        let date = try XCTUnwrap(result.date)
        XCTAssertEqual(calendar.component(.year, from: date), 2026)
        XCTAssertEqual(calendar.component(.month, from: date), 7)
        XCTAssertEqual(calendar.component(.day, from: date), 18)
    }

    func testUnderstandsCommaDecimalAndRussianTotalKeyword() {
        let result = ReceiptParser.parse(
            lines: [
                "КОФЕЙНЯ",
                "Капучино 320,00",
                "ИТОГО 320,00 ₽"
            ]
        )

        XCTAssertEqual(result.merchant, "КОФЕЙНЯ")
        XCTAssertEqual(result.total, Decimal(string: "320.00"))
    }

    func testFallsBackToLargestAmountWithoutTotalLabel() {
        let result = ReceiptParser.parse(
            lines: [
                "Corner Store",
                "Coffee 4.50",
                "Sandwich 12.90",
                "Tax 1.20"
            ]
        )

        XCTAssertEqual(result.total, Decimal(string: "12.90"))
    }

    func testReturnsNilForMissingFinancialData() {
        let result = ReceiptParser.parse(lines: ["THANK YOU", "COME AGAIN"])

        XCTAssertNil(result.total)
        XCTAssertNil(result.date)
    }
}
