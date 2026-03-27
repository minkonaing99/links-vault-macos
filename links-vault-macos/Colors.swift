import SwiftUI

// MARK: - Design tokens (dark terminal palette)

extension Color {
    static let lvBackground = Color(red: 0.051, green: 0.067, blue: 0.090)  // #0d1117
    static let lvSurface    = Color(red: 0.086, green: 0.106, blue: 0.133)  // #161b22
    static let lvBorder     = Color(red: 0.188, green: 0.212, blue: 0.239)  // #30363d
    static let lvAccent     = Color(red: 0.345, green: 0.651, blue: 1.000)  // #58a6ff
    static let lvText       = Color(red: 0.902, green: 0.929, blue: 0.953)  // #e6edf3
    static let lvMuted      = Color(red: 0.490, green: 0.522, blue: 0.565)  // #7d8590
    static let lvSaved      = Color(red: 0.247, green: 0.725, blue: 0.314)  // #3fb950
    static let lvUnread     = Color(red: 0.345, green: 0.651, blue: 1.000)  // #58a6ff
    static let lvUseful     = Color(red: 0.824, green: 0.600, blue: 0.133)  // #d29922
    static let lvArchived   = Color(red: 0.431, green: 0.463, blue: 0.506)  // #6e7681
    static let lvDanger     = Color(red: 1.000, green: 0.482, blue: 0.447)  // #ff7b72
}

// MARK: - Shared background modifier

struct AppBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(
            ZStack {
                Color.lvBackground
                RadialGradient(
                    colors: [Color.lvAccent.opacity(0.04), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 480
                )
            }
            .ignoresSafeArea()
        )
    }
}

extension View {
    func appBackground() -> some View {
        modifier(AppBackgroundModifier())
    }
}
