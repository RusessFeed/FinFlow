import XCTest
@testable import FinFlow

final class AccountRepositoryTests: XCTestCase {
    func testPreviewAccountsProduceExpectedTotal() {
        let accounts = PreviewAccountRepository().fetchAccounts()

        XCTAssertEqual(
            accounts.totalBalance(),
            Money(Decimal(string: "17350.45")!)
        )
    }
}
