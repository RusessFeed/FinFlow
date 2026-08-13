import Foundation

protocol PreferencesStore {
    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)
    func string(forKey key: String) -> String?
    func set(_ value: String, forKey key: String)
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

    func string(forKey key: String) -> String? {
        defaults.string(forKey: key)
    }

    func set(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }
}

final class InMemoryPreferences: PreferencesStore {
    private var boolValues: [String: Bool]
    private var stringValues: [String: String]

    init(values: [String: Bool] = [:], strings: [String: String] = [:]) {
        boolValues = values
        stringValues = strings
    }

    func bool(forKey key: String) -> Bool {
        boolValues[key, default: false]
    }

    func set(_ value: Bool, forKey key: String) {
        boolValues[key] = value
    }

    func string(forKey key: String) -> String? {
        stringValues[key]
    }

    func set(_ value: String, forKey key: String) {
        stringValues[key] = value
    }
}
