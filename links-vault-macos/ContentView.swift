import SwiftUI

struct ContentView: View {
    @Binding var isLoggedIn: Bool

    var body: some View {
        Group {
            if isLoggedIn {
                MainView(isLoggedIn: $isLoggedIn)
            } else {
                LoginView(isLoggedIn: $isLoggedIn)
            }
        }
        .onAppear {
            isLoggedIn = KeychainService.load(key: KeychainService.Keys.accessToken) != nil
        }
    }
}

#Preview {
    ContentView(isLoggedIn: .constant(false))
        .environment(LinksStore())
}
