import Foundation

protocol ExchangeRateCache {
    func load(baseCurrency: String) -> ExchangeRateSnapshot?
    func save(_ snapshot: ExchangeRateSnapshot)
}

final class UserDefaultsExchangeRateCache: ExchangeRateCache {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(baseCurrency: String) -> ExchangeRateSnapshot? {
        guard let data = defaults.data(forKey: key(for: baseCurrency)) else { return nil }
        return try? decoder.decode(ExchangeRateSnapshot.self, from: data)
    }

    func save(_ snapshot: ExchangeRateSnapshot) {
        guard let data = try? encoder.encode(snapshot) else { return }
        defaults.set(data, forKey: key(for: snapshot.baseCurrency))
    }

    private func key(for baseCurrency: String) -> String {
        "finflow.exchange-rates.\(baseCurrency)"
    }
}

actor CachedCurrencyRateService: CurrencyRateService {
    private let remote: CurrencyRateService
    private let cache: ExchangeRateCache

    init(remote: CurrencyRateService, cache: ExchangeRateCache) {
        self.remote = remote
        self.cache = cache
    }

    func rates(baseCurrency: String) async throws -> ExchangeRateSnapshot {
        do {
            let snapshot = try await remote.rates(baseCurrency: baseCurrency)
            cache.save(snapshot)
            return snapshot
        } catch {
            if let cached = cache.load(baseCurrency: baseCurrency) {
                return cached
            }
            throw error
        }
    }
}
