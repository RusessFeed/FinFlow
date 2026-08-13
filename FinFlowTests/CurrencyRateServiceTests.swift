import XCTest
@testable import FinFlow

final class CurrencyRateServiceTests: XCTestCase {
    func testFrankfurterServiceBuildsSnapshotFromResponse() async throws {
        let data = """
        [
          {"date":"2026-07-18","base":"USD","quote":"EUR","rate":0.86},
          {"date":"2026-07-18","base":"USD","quote":"GEL","rate":2.72}
        ]
        """.data(using: .utf8)!
        let client = StubHTTPClient(data: data, statusCode: 200)
        let fetchedAt = Date(timeIntervalSince1970: 123)
        let service = FrankfurterCurrencyRateService(client: client, now: { fetchedAt })

        let snapshot = try await service.rates(baseCurrency: "USD")

        XCTAssertEqual(snapshot.baseCurrency, "USD")
        XCTAssertEqual(snapshot.marketDate, "2026-07-18")
        XCTAssertEqual(snapshot.rates["EUR"], Decimal(string: "0.86"))
        XCTAssertEqual(snapshot.rates["GEL"], Decimal(string: "2.72"))
        XCTAssertEqual(snapshot.fetchedAt, fetchedAt)
        XCTAssertTrue(client.requestedURL?.absoluteString.contains("base=USD") == true)
    }

    func testServiceRejectsHTTPFailure() async {
        let service = FrankfurterCurrencyRateService(
            client: StubHTTPClient(data: Data(), statusCode: 503)
        )

        do {
            _ = try await service.rates(baseCurrency: "USD")
            XCTFail("Expected the request to fail")
        } catch let error as CurrencyRateError {
            guard case .serverStatus(503) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCachedServiceFallsBackToStoredRatesWhenOffline() async throws {
        let cachedSnapshot = ExchangeRateSnapshot(
            baseCurrency: "USD",
            rates: ["EUR": Decimal(string: "0.85")!],
            marketDate: "2026-07-17",
            fetchedAt: Date(timeIntervalSince1970: 100)
        )
        let cache = InMemoryExchangeRateCache(snapshot: cachedSnapshot)
        let service = CachedCurrencyRateService(
            remote: FailingCurrencyRateService(),
            cache: cache
        )

        let result = try await service.rates(baseCurrency: "USD")

        XCTAssertEqual(result, cachedSnapshot)
    }

    func testSnapshotConvertsBaseCurrency() throws {
        let snapshot = ExchangeRateSnapshot(
            baseCurrency: "USD",
            rates: ["EUR": Decimal(string: "0.8")!],
            marketDate: "2026-07-18",
            fetchedAt: .now
        )

        let result = try XCTUnwrap(snapshot.convert(Money(100), to: "EUR"))

        XCTAssertEqual(result, Money(80, currencyCode: "EUR"))
    }
}

private final class StubHTTPClient: HTTPClient {
    let data: Data
    let statusCode: Int
    private(set) var requestedURL: URL?

    init(data: Data, statusCode: Int) {
        self.data = data
        self.statusCode = statusCode
    }

    func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        requestedURL = url
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }
}

private struct FailingCurrencyRateService: CurrencyRateService {
    func rates(baseCurrency: String) async throws -> ExchangeRateSnapshot {
        throw URLError(.notConnectedToInternet)
    }
}

private final class InMemoryExchangeRateCache: ExchangeRateCache {
    private var snapshot: ExchangeRateSnapshot?

    init(snapshot: ExchangeRateSnapshot? = nil) {
        self.snapshot = snapshot
    }

    func load(baseCurrency: String) -> ExchangeRateSnapshot? {
        snapshot?.baseCurrency == baseCurrency ? snapshot : nil
    }

    func save(_ snapshot: ExchangeRateSnapshot) {
        self.snapshot = snapshot
    }
}
