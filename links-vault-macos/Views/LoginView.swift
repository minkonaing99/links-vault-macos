import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Environment(NetworkMonitor.self) private var networkMonitor

    @State private var username = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            card
                .padding(24)
        }
        .frame(minWidth: 440, minHeight: 420)
        .appBackground()
        .safeAreaInset(edge: .top, spacing: 0) {
            if !networkMonitor.isConnected {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 11))
                    Text("No internet connection")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.lvDanger.opacity(0.9))
            }
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Brand
            HStack(spacing: 7) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.lvAccent)
                Text("Link Vault")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.lvText)
            }
            .padding(.bottom, 18)

            Text("Welcome back")
                .font(.system(size: 22, weight: .bold))
                .tracking(-0.4)
                .foregroundStyle(Color.lvText)

            Text("Sign in to continue.")
                .font(.system(size: 13))
                .foregroundStyle(Color.lvMuted)
                .padding(.bottom, 20)

            // Fields
            VStack(spacing: 10) {
                fieldLabel("Username")
                TextField("Enter your username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .colorScheme(.dark)

                fieldLabel("Password")
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .colorScheme(.dark)
            }
            .padding(.bottom, 14)

            if !message.isEmpty {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.lvDanger)
                    .padding(.bottom, 10)
            }

            HStack {
                Spacer()
                Button(action: signIn) {
                    if isLoading {
                        ProgressView().controlSize(.small).tint(.white)
                    } else {
                        Text("Sign in")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.lvAccent)
                .controlSize(.small)
                .disabled(isLoading)
            }
        }
        .padding(24)
        .frame(maxWidth: 380)
        .background(Color.lvSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.lvBorder, lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)
        .frame(maxWidth: .infinity)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.lvMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func signIn() {
        guard !username.isEmpty, !password.isEmpty else {
            message = "Enter your username and password."
            return
        }
        isLoading = true
        message = ""
        Task {
            do {
                let response = try await APIClient.shared.login(username: username, password: password)
                KeychainService.save(response.accessToken, for: KeychainService.Keys.accessToken)
                KeychainService.save(response.refreshToken, for: KeychainService.Keys.refreshToken)
                isLoggedIn = true
            } catch {
                message = error.localizedDescription
            }
            isLoading = false
        }
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false))
}
