import Foundation

protocol AccountRepository {
    func fetchAccounts() -> [Account]
}

struct PreviewAccountRepository: AccountRepository {
    func fetchAccounts() -> [Account] {
        [
            Account(
                name: "Everyday",
                kind: .checking,
                balance: Money(Decimal(string: "4280.45")!),
                iconName: "building.columns.fill",
                tintHex: "#6C5CE7"
            ),
            Account(
                name: "Savings",
                kind: .savings,
                balance: Money(12_750),
                iconName: "leaf.fill",
                tintHex: "#00B894"
            ),
            Account(
                name: "Cash",
                kind: .cash,
                balance: Money(320),
                iconName: "banknote.fill",
                tintHex: "#0984E3"
            )
        ]
    }
}

extension Array where Element == Account {
    func totalBalance(currencyCode: String = "USD") -> Money {
        let total = reduce(Decimal.zero) { $0 + $1.balance.amount }
        return Money(total, currencyCode: currencyCode)
    }
}
