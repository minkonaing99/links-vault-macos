import SwiftUI

struct EditLinkView: View {
    @Environment(LinksStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let link: Link

    @State private var url: String
    @State private var title: String
    @State private var date: Date
    @State private var status: LinkStatus
    @State private var tagsText: String
    @State private var message = ""
    @State private var messageIsSuccess = false
    @State private var isSaving = false

    init(link: Link) {
        self.link = link
        _url = State(initialValue: link.url)
        _title = State(initialValue: link.title)
        _date = State(initialValue: DateFormatter.yyyyMMdd.date(from: link.date) ?? Date())
        _status = State(initialValue: link.status)
        _tagsText = State(initialValue: link.tags.joined(separator: ", "))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {

                        FormSectionHeader(title: "Edit link", subtitle: link.host)

                        FormFieldGroup("URL") {
                            TextField("https://example.com/article", text: $url)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .colorScheme(.dark)
                        }

                        FormFieldGroup("Title") {
                            TextField("Title", text: $title)
                                .textFieldStyle(.roundedBorder)
                                .colorScheme(.dark)
                        }

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
                            Button("Cancel") { dismiss() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(Color.lvMuted)
                            Spacer()
                            Button("Save changes", action: save)
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
        .navigationTitle("Edit Link")
    }

    // MARK: - Actions

    private func save() {
        let urlString = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !urlString.isEmpty, URL(string: urlString) != nil else {
            message = "Enter a valid URL."
            messageIsSuccess = false
            return
        }
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        isSaving = true
        Task {
            do {
                let body = UpdateLinkRequest(
                    url: urlString,
                    title: title,
                    date: DateFormatter.yyyyMMdd.string(from: date),
                    status: status.rawValue,
                    tags: tags,
                    pinned: link.pinned
                )
                try await store.updateLink(id: link.id, body)
                dismiss()
            } catch {
                message = error.localizedDescription
                messageIsSuccess = false
            }
            isSaving = false
        }
    }
}

#Preview {
    NavigationStack {
        EditLinkView(link: Link(
            id: "1", url: "https://example.com", title: "Example",
            host: "example.com", date: "2025-01-01", status: .saved,
            tags: ["swift", "ios"], pinned: false
        ))
        .environment(LinksStore())
    }
}
