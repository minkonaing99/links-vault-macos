import SwiftUI

@main
struct links_vault_macosApp: App {
    @State private var store = LinksStore()
    @State private var isLoggedIn = false

    var body: some Scene {
        #if os(macOS)
        WindowGroup(id: "main") {
            ContentView(isLoggedIn: $isLoggedIn)
                .environment(store)
        }
        .defaultSize(width: 1040, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra("LinkVault", systemImage: "link") {
            MenuBarView(isLoggedIn: $isLoggedIn)
                .environment(store)
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            ContentView(isLoggedIn: $isLoggedIn)
                .environment(store)
        }
        #endif
    }
}
