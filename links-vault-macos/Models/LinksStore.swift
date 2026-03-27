import SwiftUI

@MainActor
@Observable
final class LinksStore {
    var links: [Link] = []
    var isLoading = false
    var errorMessage: String? = nil

    init() {
        links = LinksCache.load()
    }

    func fetchLinks(search: String? = nil, status: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.fetchLinks(search: search, status: status)
            links = response.links
            persist()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createLink(_ body: CreateLinkRequest) async throws -> Link {
        let link = try await APIClient.shared.createLink(body)
        links = [link] + links
        persist()
        return link
    }

    func updateLink(id: String, _ body: UpdateLinkRequest) async throws {
        let snapshot = links
        do {
            let updated = try await APIClient.shared.updateLink(id: id, body)
            links = links.map { $0.id == id ? updated : $0 }
            persist()
        } catch {
            links = snapshot
            throw error
        }
    }

    func togglePin(id: String) async {
        guard let link = links.first(where: { $0.id == id }) else { return }
        let newPinned = !link.pinned
        links = links.map { $0.id == id ? $0.withPinned(newPinned) : $0 }
        let body = UpdateLinkRequest(
            url: link.url,
            title: link.title,
            date: link.date,
            status: link.status.rawValue,
            tags: link.tags,
            pinned: newPinned
        )
        do {
            let updated = try await APIClient.shared.updateLink(id: id, body)
            links = links.map { $0.id == id ? updated : $0 }
            persist()
        } catch {
            links = links.map { $0.id == id ? link : $0 }
        }
    }

    func delete(id: String) async {
        let snapshot = links
        links = links.filter { $0.id != id }
        do {
            try await APIClient.shared.deleteLink(id: id)
            persist()
        } catch {
            links = snapshot
        }
    }

    var recent: [Link] {
        Array(links.filter { !$0.pinned }.prefix(5))
    }

    private func persist() {
        let snapshot = links
        Task.detached(priority: .background) { LinksCache.save(snapshot) }
    }
}
