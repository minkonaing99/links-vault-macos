import SwiftUI
import UniformTypeIdentifiers

private enum SortMode: String, CaseIterable, Identifiable {
    case recent    = "Most recent"
    case dateAsc   = "Oldest first"
    case titleAsc  = "Title A–Z"
    case titleDesc = "Title Z–A"
    var id: String { rawValue }
}

struct BrowseView: View {
    @Environment(LinksStore.self) private var store

    @State private var searchText = ""
    @State private var statusFilter: LinkStatus? = nil
    @State private var sortMode: SortMode = .recent
    @State private var editingLink: Link? = nil
    @State private var isShowingShareSheet = false
    @State private var exportedFileURL: URL? = nil

    var body: some View {
        // Capture store properties here — @Observable tracks dependencies at the
        // point of access in body, not inside nested computed properties.
        let links    = store.links
        let loading  = store.isLoading
        let errorMsg = store.errorMessage

        let filtered = filter(links)
        let grouped  = group(filtered)

        ScrollView {
            VStack(spacing: 12) {
                filtersSection
                librarySection(
                    filtered: filtered,
                    grouped: grouped,
                    total: links.count,
                    isLoading: loading,
                    errorMessage: errorMsg,
                    onExport: { exportJSON(filtered) }
                )
            }
            .padding(16)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .appBackground()
        .navigationTitle("Browse")
        .task { await store.fetchLinks() }
        .refreshable { await store.fetchLinks(search: searchText.isEmpty ? nil : searchText) }
        .onChange(of: searchText) { _, _ in
            Task { await store.fetchLinks(search: searchText.isEmpty ? nil : searchText) }
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await store.fetchLinks(search: searchText.isEmpty ? nil : searchText) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(store.isLoading)
            }
        }
        #endif
        #if os(iOS)
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(items: [url])
            }
        }
        #endif
        .sheet(item: $editingLink) { link in
            NavigationStack {
                EditLinkView(link: link)
            }
        }
    }

    // MARK: - Filtering & grouping

    private func filter(_ links: [Link]) -> [Link] {
        let query = searchText.lowercased()
        return links
            .filter { link in
                if let s = statusFilter, link.status != s { return false }
                if query.isEmpty { return true }
                return [link.title, link.url, link.host, link.date]
                    .joined(separator: " ").lowercased().contains(query)
                    || link.tags.joined(separator: " ").lowercased().contains(query)
            }
            .sorted { a, b in
                if a.pinned != b.pinned { return a.pinned }
                switch sortMode {
                case .titleAsc:  return a.title.lowercased() < b.title.lowercased()
                case .titleDesc: return a.title.lowercased() > b.title.lowercased()
                case .dateAsc:   return a.date < b.date
                case .recent:    return a.date > b.date
                }
            }
    }

    private func group(_ filtered: [Link]) -> [(label: String, links: [Link])] {
        var pinned: [Link] = []
        var byDate: [String: [Link]] = [:]
        for link in filtered {
            if link.pinned { pinned.append(link) }
            else { byDate[link.date, default: []].append(link) }
        }
        var result: [(label: String, links: [Link])] = []
        if !pinned.isEmpty { result.append((label: "Pinned", links: pinned)) }
        for date in byDate.keys.sorted().reversed() {
            result.append((label: groupLabel(for: date), links: byDate[date]!))
        }
        return result
    }

    // MARK: - Filters section

    private var filtersSection: some View {
        SurfaceCard {
            VStack(spacing: 8) {
                TextField("Search title, host, tags, URL", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .colorScheme(.dark)

                HStack(spacing: 6) {
                    Picker("Status", selection: $statusFilter) {
                        Text("All statuses").tag(Optional<LinkStatus>.none)
                        ForEach(LinkStatus.allCases) { status in
                            Text(status.label).tag(Optional(status))
                        }
                    }
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)

                    Picker("Sort", selection: $sortMode) {
                        ForEach(SortMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
                }
            }
            .padding(12)
        }
    }

    // MARK: - Library section

    private func librarySection(
        filtered: [Link],
        grouped: [(label: String, links: [Link])],
        total: Int,
        isLoading: Bool,
        errorMessage: String?,
        onExport: @escaping () -> Void
    ) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Library")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.lvText)
                        Text("\(filtered.count) visible of \(total) total")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.lvMuted)
                    }
                    Spacer()
                    Button("Export JSON", action: onExport)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(Color.lvAccent)
                        .disabled(filtered.isEmpty)
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
                } else if filtered.isEmpty {
                    Text("No links match your current filters.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.lvMuted)
                        .padding(14)
                } else {
                    ForEach(grouped, id: \.label) { group in
                        groupSection(group)
                    }
                }
            }
        }
    }

    private func groupSection(_ group: (label: String, links: [Link])) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.lvMuted)
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 4)

            ForEach(Array(group.links.enumerated()), id: \.element.id) { index, link in
                if index > 0 {
                    Divider().background(Color.lvBorder).padding(.horizontal, 12)
                }
                LinkRowView(
                    link: link,
                    onTogglePin: { Task { await store.togglePin(id: link.id) } },
                    onDelete: { Task { await store.delete(id: link.id) } },
                    onEdit: { editingLink = link }
                )
            }
        }
    }

    // MARK: - Export

    private func exportJSON(_ links: [Link]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(links) else { return }

        #if os(macOS)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "links-export.json"
        panel.allowedContentTypes = [.json]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? data.write(to: url)
        }
        #else
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("links-export.json")
        try? data.write(to: url)
        exportedFileURL = url
        isShowingShareSheet = true
        #endif
    }

    private func groupLabel(for date: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: date) else { return "Earlier · \(date)" }
        if Calendar.current.isDateInToday(d) { return "Today" }
        if Calendar.current.isDateInYesterday(d) { return "Yesterday" }
        return "Earlier · \(date)"
    }
}

#if os(iOS)
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    NavigationStack {
        BrowseView().environment(LinksStore())
    }
}
