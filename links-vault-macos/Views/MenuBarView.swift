#if os(macOS)
import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(LinksStore.self) private var store
    @Binding var isLoggedIn: Bool
    @Environment(\.openURL) private var openURL
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        let recent = store.recent
        let pinned = store.links.filter { $0.pinned }

        VStack(alignment: .leading, spacing: 0) {
            if !isLoggedIn {
                Text("Not logged in")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.lvMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            } else if recent.isEmpty && pinned.isEmpty {
                Text("No links saved yet")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.lvMuted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            } else {
                if !recent.isEmpty {
                    sectionHeader("Recent")
                    ForEach(recent) { link in
                        linkRow(link)
                    }
                }

                if !pinned.isEmpty {
                    if !recent.isEmpty {
                        Divider().background(Color.lvBorder).padding(.vertical, 4)
                    }
                    sectionHeader("Pinned")
                    ForEach(pinned) { link in
                        linkRow(link)
                    }
                }
            }

            Divider().background(Color.lvBorder).padding(.vertical, 4)

            Button(action: openMainWindow) {
                Text("Open LinkVault")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.lvAccent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: { NSApp.terminate(nil) }) {
                Text("Quit")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.lvDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
        .frame(width: 280)
        .background(Color.lvSurface)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.lvMuted)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 2)
    }

    private func linkRow(_ link: Link) -> some View {
        LinkRowItem(link: link)
    }

    private func openMainWindow() {
        let mainWindow = NSApp.windows.first { !($0 is NSPanel) && $0.canBecomeMain }
        if let mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct LinkRowItem: View {
    let link: Link
    @Environment(\.openURL) private var openURL
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Button {
                if let url = URL(string: link.url) {
                    openURL(url)
                }
            } label: {
                Text(link.title)
                    .font(.system(size: 12))
                    .foregroundStyle(isHovered ? Color.lvAccent : Color.lvText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .help(link.url)

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(link.url, forType: .string)
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.lvMuted)
            }
            .buttonStyle(.plain)
            .help("Copy link")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .onHover { isHovered = $0 }
    }
}
#endif
