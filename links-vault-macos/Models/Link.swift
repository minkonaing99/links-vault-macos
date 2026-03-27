import SwiftUI

enum LinkStatus: String, CaseIterable, Identifiable, Codable {
    case saved, unread, useful, archived

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .saved:    return .lvSaved
        case .unread:   return .lvUnread
        case .useful:   return .lvUseful
        case .archived: return .lvArchived
        }
    }
}

struct Link: Identifiable, Equatable, Codable {
    let id: String
    let url: String
    let title: String
    let host: String
    let date: String
    let status: LinkStatus
    let tags: [String]
    let pinned: Bool

    func withPinned(_ value: Bool) -> Link {
        Link(id: id, url: url, title: title, host: host,
             date: date, status: status, tags: tags, pinned: value)
    }

}
