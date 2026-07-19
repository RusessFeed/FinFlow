import Foundation

protocol CurrencyRateService {
    func rates(baseCurrency: String) async throws -> ExchangeRateSnapshot
}

enum CurrencyRateError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverStatus(Int)
    case emptyRates
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Could not create the exchange-rate request."
        case .invalidResponse: "The exchange-rate response was invalid."
        case .serverStatus(let status): "The exchange-rate server returned status \(status)."
        case .emptyRates: "No exchange rates were returned."
        case .unavailable: "Exchange rates are currently unavailable."
        }
    }
}

struct FrankfurterCurrencyRateService: CurrencyRateService {
    private let client: HTTPClient
    private let now: () -> Date

    init(client: HTTPClient, now: @escaping () -> Date = Date.init) {
        self.client = client
        self.now = now
    }

    func rates(baseCurrency: String) async throws -> ExchangeRateSnapshot {
        var components = URLComponents(string: "https://api.frankfurter.dev/v2/rates")
        components?.queryItems = [
            URLQueryItem(name: "base", value: baseCurrency),
            URLQueryItem(name: "quotes", value: "EUR,GBP,GEL,JPY")
        ]
        guard let url = components?.url else { throw CurrencyRateError.invalidURL }
        let (data, response) = try await client.data(from: url)
        guard (200..<300).contains(response.statusCode) else {
            throw CurrencyRateError.serverStatus(response.statusCode)
        }
        let values = try JSONDecoder().decode([RateResponse].self, from: data)
        guard let marketDate = values.first?.date, !values.isEmpty else {
            throw CurrencyRateError.emptyRates
        }
        return ExchangeRateSnapshot(
            baseCurrency: baseCurrency,
            rates: Dictionary(uniqueKeysWithValues: values.map { ($0.quote, $0.rate) }),
            marketDate: marketDate,
            fetchedAt: now()
        )
    }
}

private struct RateResponse: Decodable {
    let date: String
    let base: String
    let quote: String
    let rate: Decimal
}

struct UnavailableCurrencyRateService: CurrencyRateService {
    func rates(baseCurrency: String) async throws -> ExchangeRateSnapshot {
        throw CurrencyRateError.unavailable
    }
}
