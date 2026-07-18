import Foundation

struct Money: Codable, Equatable, Hashable {
    let amount: Decimal
    let currencyCode: String

    init(_ amount: Decimal, currencyCode: String = "USD") {
        self.amount = amount
        self.currencyCode = currencyCode
    }

    static func + (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currencyCode == rhs.currencyCode, "Currencies must match")
        return Money(lhs.amount + rhs.amount, currencyCode: lhs.currencyCode)
    }

    func formatted(locale: Locale = .current) -> String {
        amount.formatted(
            .currency(code: currencyCode)
                .locale(locale)
                .precision(.fractionLength(2))
        )
    }
}
