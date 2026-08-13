import XCTest
@testable import FinFlow

final class MoneyTests: XCTestCase {
    func testAddingMoneyWithMatchingCurrency() {
        let result = Money(125.50) + Money(74.50)

        XCTAssertEqual(result, Money(200))
    }

    func testFormattingUsesCurrencyAndTwoFractionDigits() {
        let locale = Locale(identifier: "en_US")

        XCTAssertEqual(Money(42.5).formatted(locale: locale), "$42.50")
    }
}
