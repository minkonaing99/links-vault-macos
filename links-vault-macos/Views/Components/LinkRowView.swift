import SwiftUI

struct LinkRowView: View {
    let link: Link
    let showActions: Bool
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var showDeleteConfirm = false

    init(
        link: Link,
        showActions: Bool = true,
        onTogglePin: @escaping () -> Void = {},
        onDelete: @escaping () -> Void = {},
        onEdit: @escaping () -> Void = {}
    ) {
        self.link = link
        self.showActions = showActions
        self.onTogglePin = onTogglePin
        self.onDelete = onDelete
        self.onEdit = onEdit
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StatusDot(status: link.status)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 3) {
                // Title — tappable, opens URL
                Button {
                    if let url = URL(string: link.url) { openURL(url) }
                } label: {
                    Text(link.title.isEmpty ? link.url : link.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.lvText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                HStack(spacing: 4) {
                    Text(link.host)
                        .font(.system(size: 11, design: .monospaced))
                    Text("·")
                    Text(link.date)
                    Text("·")
                    Text(link.status.label)
                }
                .font(.system(size: 11))
                .foregroundStyle(Color.lvMuted)

                if !link.tags.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(link.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color.lvAccent.opacity(0.15))
                                .foregroundStyle(Color.lvAccent)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            if showActions {
                HStack(spacing: 4) {
                    // Pin button — explicit contentShape for reliable hit testing
                    Button(action: onTogglePin) {
                        Image(systemName: link.pinned ? "pin.fill" : "pin")
                            .font(.system(size: 11))
                            .foregroundStyle(link.pinned ? Color.lvAccent : Color.lvMuted)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())

                    Menu {
                        Button("Edit") { onEdit() }
                        Divider()
                        Button("Delete", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.lvMuted)
                            .frame(width: 22, height: 22)
                            .background(Color.lvBorder.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .fixedSize()
                }
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 14)
        .confirmationDialog("Delete this link?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(link.title)
        }
    }
}
