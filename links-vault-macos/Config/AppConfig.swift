import Foundation

enum AppConfig {
    #if DEBUG
    static let baseURL = URL(string: "https://links.merxy.club")!
    #else
    static let baseURL = URL(string: "https://links.merxy.club")!
    #endif
}
