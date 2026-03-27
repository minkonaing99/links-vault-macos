import Foundation

enum LinksCache {
    private static let url: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("linkvault_links.json")
    }()

    static func load() -> [Link] {
        guard let data = try? Data(contentsOf: url),
              let links = try? JSONDecoder().decode([Link].self, from: data)
        else { return [] }
        return links
    }

    static func save(_ links: [Link]) {
        guard let data = try? JSONEncoder().encode(links) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
