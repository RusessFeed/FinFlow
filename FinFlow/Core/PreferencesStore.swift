import Foundation

protocol PreferencesStore {
    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)
}

final class UserDefaultsPreferences: PreferencesStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func bool(forKey key: String) -> Bool {
        defaults.bool(forKey: key)
    }

    func set(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}

final class InMemoryPreferences: PreferencesStore {
    private var values: [String: Bool]

    init(values: [String: Bool] = [:]) {
        self.values = values
    }

    func bool(forKey key: String) -> Bool {
        values[key, default: false]
    }

    func set(_ value: Bool, forKey key: String) {
        values[key] = value
    }
}
