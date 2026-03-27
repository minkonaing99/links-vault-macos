import SwiftUI

struct HomeView: View {
    @Environment(LinksStore.self) private var store

    @State private var quickAddURL = ""
    @State private var quickAddMessage = ""
    @State private var quickAddSuccess = false
    @State private var isSaving = false

    var body: some View {
        let recent   = store.recent
        let loading  = store.isLoading
        let errorMsg = store.errorMessage

        ScrollView {
            VStack(spacing: 12) {
                quickAddSection
                recentSection(recent, isLoading: loading, errorMessage: errorMsg)
            }
            .padding(16)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .appBackground()
        .navigationTitle("Home")
        .task { await store.fetchLinks() }
    }

    // MARK: - Quick Add

    private var quickAddSection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quick Add")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.lvText)
                    Text("Paste a URL and save it with an auto-fetched title.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lvMuted)
                }

                HStack(spacing: 6) {
                    TextField("https://example.com/article", text: $quickAddURL)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .colorScheme(.dark)

                    Button("Paste", action: pasteFromClipboard)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(Color.lvAccent)
                }

                if !quickAddMessage.isEmpty {
                    Text(quickAddMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(quickAddSuccess ? Color.lvSaved : Color.lvDanger)
                }

                HStack {
                    Spacer()
                    Button("Save", action: saveQuickAdd)
                        .buttonStyle(.borderedProminent)
                        .tint(Color.lvAccent)
                        .controlSize(.small)
                        .disabled(quickAddURL.isEmpty || isSaving)
                }
            }
            .padding(14)
        }
    }

    // MARK: - Recent

    private func recentSection(_ recent: [Link], isLoading: Bool, errorMessage: String?) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recent")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.lvText)
                        Text("Latest saved items.")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.lvMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)

                Divider().background(Color.lvBorder)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let err = errorMessage {
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lvDanger)
                        .padding(14)
                } else if recent.isEmpty {
                    Text("No links saved yet.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.lvMuted)
                        .padding(14)
                } else {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, link in
                        if index > 0 {
                            Divider().background(Color.lvBorder).padding(.horizontal, 12)
                        }
                        LinkRowView(link: link, showActions: false)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func pasteFromClipboard() {
        #if os(macOS)
        let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        #else
        let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        #endif
        if text.isEmpty {
            quickAddMessage = "Clipboard is empty."
            quickAddSuccess = false
        } else {
            quickAddURL = text
            quickAddMessage = ""
        }
    }

    private func saveQuickAdd() {
        let urlString = quickAddURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty, URL(string: urlString) != nil else {
            quickAddMessage = "Enter a valid URL."
            quickAddSuccess = false
            return
        }
        if store.links.contains(where: { $0.url.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/")) == urlString.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/")) }) {
            quickAddMessage = "This URL is already saved."
            quickAddSuccess = false
            return
        }
        isSaving = true
        quickAddMessage = ""
        Task {
            do {
                var resolvedTitle = URL(string: urlString)?.host ?? urlString
                if let fetched = try? await APIClient.shared.fetchTitle(url: urlString) {
                    resolvedTitle = fetched.title
                }
                let body = CreateLinkRequest(
                    url: urlString,
                    title: resolvedTitle,
                    date: DateFormatter.yyyyMMdd.string(from: Date()),
                    status: "saved",
                    tags: [],
                    pinned: false
                )
                _ = try await store.createLink(body)
                quickAddURL = ""
                quickAddMessage = "Link saved."
                quickAddSuccess = true
            } catch {
                quickAddMessage = error.localizedDescription
                quickAddSuccess = false
            }
            isSaving = false
        }
    }
}

#Preview {
    HomeView().environment(LinksStore())
}
