import SwiftUI

struct AddLinkView: View {
    @Environment(LinksStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var url = ""
    @State private var title = ""
    @State private var date = Date()
    @State private var status: LinkStatus = .saved
    @State private var tagsText = ""
    @State private var message = ""
    @State private var messageIsSuccess = false
    @State private var isFetching = false
    @State private var isSaving = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {

                        FormSectionHeader(title: "Add a link", subtitle: "Tracking parameters are cleaned automatically.")

                        // URL row
                        FormFieldGroup("URL") {
                            HStack(spacing: 6) {
                                TextField("https://example.com/article", text: $url)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .colorScheme(.dark)
                                Button("Paste", action: pasteURL)
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .tint(Color.lvAccent)
                                Button("Fetch", action: fetchTitle)
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .tint(Color.lvAccent)
                                    .disabled(isFetching)
                            }
                        }

                        // Title
                        FormFieldGroup("Title") {
                            TextField("Optional title", text: $title)
                                .textFieldStyle(.roundedBorder)
                                .colorScheme(.dark)
                        }

                        // Date + Status in same row
                        HStack(alignment: .top, spacing: 12) {
                            FormFieldGroup("Date") {
                                DatePicker("", selection: $date, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            FormFieldGroup("Status") {
                                Picker("", selection: $status) {
                                    ForEach(LinkStatus.allCases) { s in
                                        Text(s.label).tag(s)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(Color.lvAccent)
                                .colorScheme(.dark)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Tags
                        FormFieldGroup("Tags") {
                            TextField("security, cloud, certification", text: $tagsText)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .colorScheme(.dark)
                        }

                        if !message.isEmpty {
                            Text(message)
                                .font(.system(size: 12))
                                .foregroundStyle(messageIsSuccess ? Color.lvSaved : Color.lvDanger)
                        }

                        HStack {
                            Spacer()
                            Button("Save link", action: saveLink)
                                .buttonStyle(.borderedProminent)
                                .tint(Color.lvAccent)
                                .controlSize(.small)
                                .disabled(url.isEmpty || isSaving)
                        }
                    }
                    .padding(14)
                }
            }
            .padding(16)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .appBackground()
        .navigationTitle("Add Link")
    }

    // MARK: - Actions

    private func pasteURL() {
        #if os(macOS)
        let text = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        #else
        let text = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        #endif
        guard !text.isEmpty else {
            setMessage("Clipboard is empty.", success: false)
            return
        }
        url = text
        setMessage("", success: false)
    }

    private func fetchTitle() {
        guard !url.isEmpty else {
            setMessage("Enter a URL first.", success: false)
            return
        }
        isFetching = true
        Task {
            do {
                let response = try await APIClient.shared.fetchTitle(url: url)
                title = response.title
                setMessage("Title fetched.", success: true)
            } catch {
                setMessage(error.localizedDescription, success: false)
            }
            isFetching = false
        }
    }

    private func saveLink() {
        let urlString = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty, URL(string: urlString) != nil else {
            setMessage("Enter a valid URL.", success: false)
            return
        }
        if store.links.contains(where: { $0.url.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/")) == urlString.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "/")) }) {
            setMessage("This URL is already saved.", success: false)
            return
        }
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        isSaving = true
        Task {
            do {
                let body = CreateLinkRequest(
                    url: urlString,
                    title: title.isEmpty ? (URL(string: urlString)?.host ?? urlString) : title,
                    date: DateFormatter.yyyyMMdd.string(from: date),
                    status: status.rawValue,
                    tags: tags,
                    pinned: false
                )
                _ = try await store.createLink(body)
                setMessage("Link saved.", success: true)
                url = ""
                title = ""
                tagsText = ""
                date = Date()
                status = .saved
            } catch {
                setMessage(error.localizedDescription, success: false)
            }
            isSaving = false
        }
    }

    private func setMessage(_ text: String, success: Bool) {
        message = text
        messageIsSuccess = success
    }
}

#Preview {
    NavigationStack {
        AddLinkView().environment(LinksStore())
    }
}
