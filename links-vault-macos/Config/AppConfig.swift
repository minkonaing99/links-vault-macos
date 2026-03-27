import Foundation

enum AppConfig {
    #if DEBUG
    static let baseURL = URL(string: "http://localhost:3080")!
    #else
    static let baseURL = URL(string: "https://links.merxy.club")!
    #endif
}
