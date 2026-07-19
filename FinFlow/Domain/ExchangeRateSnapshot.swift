import Foundation

struct ExchangeRateSnapshot: Codable, Equatable {
    let baseCurrency: String
    let rates: [String: Decimal]
    let marketDate: String
    let fetchedAt: Date

    func rate(for currencyCode: String) -> Decimal? {
        currencyCode == baseCurrency ? 1 : rates[currencyCode]
    }

    func convert(_ money: Money, to targetCurrency: String) -> Money? {
        guard money.currencyCode == baseCurrency,
              let rate = rate(for: targetCurrency) else { return nil }
        return Money(money.amount * rate, currencyCode: targetCurrency)
    }
}
