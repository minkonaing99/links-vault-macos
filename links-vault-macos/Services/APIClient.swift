import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private var isRefreshing = false

    // MARK: - Auth endpoints

    func login(username: String, password: String) async throws -> TokenResponse {
        let body = TokenRequest(username: username, password: password)
        let req = try makeRequest(path: "/api/auth/token", method: "POST", body: body, auth: false)
        return try await perform(req, retryOnUnauthorized: false)
    }

    func refreshTokens() async throws {
        guard let refreshToken = KeychainService.load(key: KeychainService.Keys.refreshToken) else {
            throw APIError.unauthorized
        }
        let body = RefreshRequest(refreshToken: refreshToken)
        let req = try makeRequest(path: "/api/auth/refresh", method: "POST", body: body, auth: false)
        let response: TokenResponse = try await perform(req, retryOnUnauthorized: false)
        KeychainService.save(response.accessToken, for: KeychainService.Keys.accessToken)
        KeychainService.save(response.refreshToken, for: KeychainService.Keys.refreshToken)
    }

    func logout() async {
        guard let refreshToken = KeychainService.load(key: KeychainService.Keys.refreshToken) else {
            KeychainService.clearAll()
            return
        }
        let body = LogoutRequest(refreshToken: refreshToken)
        if let req = try? makeRequest(path: "/api/auth/logout", method: "POST", body: body, auth: true) {
            _ = try? await session.data(for: req)
        }
        KeychainService.clearAll()
    }

    // MARK: - Link endpoints

    func fetchLinks(search: String? = nil, status: String? = nil, sort: String = "updatedAt", order: String = "desc", limit: Int = 200) async throws -> LinksResponse {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort",  value: sort),
            URLQueryItem(name: "order", value: order),
        ]
        if let q = search, !q.isEmpty { items.append(URLQueryItem(name: "q", value: q)) }
        if let s = status              { items.append(URLQueryItem(name: "status", value: s)) }

        let req = try makeRequest(path: "/api/links", queryItems: items)
        return try await perform(req)
    }

    func createLink(_ body: CreateLinkRequest) async throws -> Link {
        let req = try makeRequest(path: "/api/links", method: "POST", body: body)
        let wrapper: SingleLinkResponse = try await perform(req)
        return wrapper.entry
    }

    func updateLink(id: String, _ body: UpdateLinkRequest) async throws -> Link {
        let req = try makeRequest(path: "/api/links/\(id)", method: "PUT", body: body)
        let wrapper: SingleLinkResponse = try await perform(req)
        return wrapper.entry
    }

    func deleteLink(id: String) async throws {
        let req = try makeRequest(path: "/api/links/\(id)", method: "DELETE")
        try await performVoid(req)
    }

    func fetchTitle(url: String) async throws -> TitleFetchResponse {
        let items = [URLQueryItem(name: "url", value: url)]
        let req = try makeRequest(path: "/api/fetch-title", queryItems: items)
        return try await perform(req)
    }

    // MARK: - Request builder

    private func makeRequest(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: (some Encodable)? = nil as String?,
        auth: Bool = true
    ) throws -> URLRequest {
        var components = URLComponents(url: AppConfig.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty { components.queryItems = queryItems }

        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if auth, let token = KeychainService.load(key: KeychainService.Keys.accessToken) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            req.httpBody = try encoder.encode(body)
        }
        return req
    }

    // MARK: - Perform

    private func perform<T: Decodable>(_ request: URLRequest, retryOnUnauthorized: Bool = true) async throws -> T {
        let (data, response) = try await fetch(request)
        let http = response as! HTTPURLResponse

        if http.statusCode == 401 && retryOnUnauthorized {
            try await refreshAccessToken()
            var retried = request
            if let token = KeychainService.load(key: KeychainService.Keys.accessToken) {
                retried.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let (data2, _) = try await fetch(retried)
            return try decode(T.self, from: data2)
        }

        try checkStatus(http.statusCode, data: data)
        return try decode(T.self, from: data)
    }

    private func performVoid(_ request: URLRequest) async throws {
        let (data, response) = try await fetch(request)
        let http = response as! HTTPURLResponse
        try checkStatus(http.statusCode, data: data)
    }

    private func fetch(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.network(error)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    private func checkStatus(_ code: Int, data: Data) throws {
        guard !(200...299).contains(code) else { return }
        let message = (try? decoder.decode(APIErrorBody.self, from: data))?.error ?? HTTPURLResponse.localizedString(forStatusCode: code)
        switch code {
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        case 409: throw APIError.conflict(message)
        default:  throw APIError.server(message)
        }
    }

    // MARK: - Token refresh (deduplicated)

    private func refreshAccessToken() async throws {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        try await refreshTokens()
    }
}

// Server wraps single-link responses as { ok, entry }
private struct SingleLinkResponse: Decodable {
    let entry: Link
}
