import SwiftUI

private enum NavSelection: Hashable {
    case home, browse, addLink
}

struct MainView: View {
    @Environment(LinksStore.self) private var store
    @Binding var isLoggedIn: Bool

    #if os(macOS)
    @State private var selection: NavSelection? = .home
    #endif

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        #else
        iOSTabView
        #endif
    }

    // MARK: - macOS

    #if os(macOS)
    private var sidebar: some View {
        List(selection: $selection) {
            Section {
                Label("Home", systemImage: "house.fill")
                    .tag(NavSelection.home)
                Label("Browse", systemImage: "books.vertical.fill")
                    .tag(NavSelection.browse)
                Label("Add Link", systemImage: "plus.circle.fill")
                    .tag(NavSelection.addLink)
            }

            Section {
                Button(action: logout) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(Color.lvDanger)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Link Vault")
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .home {
        case .home:    HomeView()
        case .browse:  BrowseView()
        case .addLink: AddLinkView()
        }
    }
    #endif

    // MARK: - iOS

    #if os(iOS)
    private var iOSTabView: some View {
        TabView {
            NavigationStack {
                HomeView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Logout", action: logout)
                        }
                    }
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                BrowseView()
            }
            .tabItem { Label("Browse", systemImage: "books.vertical.fill") }

            NavigationStack {
                AddLinkView()
            }
            .tabItem { Label("Add", systemImage: "plus.circle.fill") }
        }
        .tint(Color.lvAccent)
    }
    #endif

    // MARK: - Actions

    private func logout() {
        Task { await APIClient.shared.logout() }
        isLoggedIn = false
    }
}

#Preview {
    MainView(isLoggedIn: .constant(true))
        .environment(LinksStore())
}
