import Foundation

// MARK: - Auth

struct TokenRequest: Encodable {
    let username: String
    let password: String
}

struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}

struct RefreshRequest: Encodable {
    let refreshToken: String
}

struct LogoutRequest: Encodable {
    let refreshToken: String
}

// MARK: - Links

struct LinksResponse: Decodable {
    let links: [Link]
}

struct CreateLinkRequest: Encodable {
    let url: String
    let title: String
    let date: String
    let status: String
    let tags: [String]
    let pinned: Bool
}

struct UpdateLinkRequest: Encodable {
    let url: String
    let title: String
    let date: String
    let status: String
    let tags: [String]
    let pinned: Bool
}

// MARK: - Title fetch

struct TitleFetchResponse: Decodable {
    let title: String
    let url: String
    let host: String
}

// MARK: - Generic error body

struct APIErrorBody: Decodable {
    let error: String
}

// MARK: - App-level error

enum APIError: LocalizedError {
    case unauthorized
    case conflict(String)
    case notFound
    case server(String)
    case network(Error)
    case decoding(Error)
    case unknown(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:        return "Session expired. Please sign in again."
        case .conflict(let msg):   return msg
        case .notFound:            return "Not found."
        case .server(let msg):     return msg
        case .network(let err):    return "Network error: \(err.localizedDescription)"
        case .decoding(let err):   return "Unexpected response: \(err.localizedDescription)"
        case .unknown(let code):   return "Unexpected error (HTTP \(code))."
        }
    }
}
