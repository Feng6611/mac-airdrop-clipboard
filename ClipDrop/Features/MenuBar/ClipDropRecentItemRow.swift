import SwiftUI

struct ClipDropRecentItemRow: View {
    let item: ClipboardHistoryItem
    let isSending: Bool
    let isSelected: Bool
    let send: () -> Void
    let copy: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: ClipDropDesignToken.Spacing.rowHorizontal) {
            Button(action: send) {
                HStack(spacing: ClipDropDesignToken.Spacing.rowHorizontal) {
                    contentTypeIcon

                    Text(item.textForDisplay)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isSending)
            .accessibilityLabel("Send \(item.contentType.displayName) via AirDrop")
            .help("Send via AirDrop")

            ClipDropIconActionButton(
                systemName: "doc.on.doc",
                label: "Copy",
                action: copy
            )
            .opacity(showsSecondaryActions ? 1 : 0)
            .accessibilityHidden(!showsSecondaryActions)

            ClipDropIconActionButton(
                systemName: "paperplane",
                label: "Send via AirDrop",
                action: send
            )
            .disabled(isSending)
        }
        .padding(.vertical, ClipDropDesignToken.Spacing.rowVertical)
        .padding(.horizontal, ClipDropDesignToken.Spacing.rowHorizontal)
        .frame(minHeight: ClipDropDesignToken.Size.rowMinHeight)
        .background(rowBackground)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .contextMenu {
            Button(action: send) {
                Label("Send via AirDrop", systemImage: "paperplane")
            }
            .disabled(isSending)

            Button(action: copy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }

    private var showsSecondaryActions: Bool {
        isHovering || isSelected
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(isHovering || isSelected ? ClipDropDesignToken.Colors.rowHover : Color.clear)
    }

    private var contentTypeIcon: some View {
        Image(systemName: item.contentType.systemImageName)
            .symbolRenderingMode(.hierarchical)
            .font(.body.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(width: ClipDropDesignToken.Size.leadingIcon, height: ClipDropDesignToken.Size.leadingIcon)
            .accessibilityHidden(true)
    }
}

private extension ClipboardHistoryItem {
    var textForDisplay: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
