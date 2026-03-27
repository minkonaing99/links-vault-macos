import Foundation

enum KeychainService {
    static func save(_ value: String, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    static func load(key: String) -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: Keys.accessToken)
        UserDefaults.standard.removeObject(forKey: Keys.refreshToken)
    }

    enum Keys {
        static let accessToken  = "accessToken"
        static let refreshToken = "refreshToken"
    }
}
