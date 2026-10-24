import AppKit
import SwiftUI

struct ClipDropRecentItemRow: View {
    let item: ClipboardHistoryItem
    let isSelected: Bool
    let isSelectionMode: Bool
    let isMergeSelected: Bool
    let send: () -> Void
    let copy: () -> Void
    let editAndSend: () -> Void
    let showQRCode: () -> Void
    let toggleMergeSelection: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: isSelectionMode ? toggleMergeSelection : send) {
            HStack(spacing: ClipDropDesignToken.Spacing.rowHorizontal) {
                if isSelectionMode {
                    Image(systemName: isMergeSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(.secondary)
                        .frame(width: ClipDropDesignToken.Size.iconButtonHit, height: ClipDropDesignToken.Size.iconButtonHit)
                }

                contentPreview

                Text(item.textForDisplay)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 4)
                if !isSelectionMode {
                    Image(systemName: "paperplane")
                        .foregroundStyle(.secondary)
                        .frame(width: ClipDropDesignToken.Size.iconButtonHit, height: ClipDropDesignToken.Size.iconButtonHit)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(item.preview)
        .help(isSelectionMode ? "Select item" : "Send via AirDrop")
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

            if item.isEditableText {
                Button(action: editAndSend) {
                    Label("Edit and Send…", systemImage: "square.and.pencil")
                }
                Button(action: showQRCode) {
                    Label("Show QR Code", systemImage: "qrcode")
                }
            }

            Divider()

            Button(action: copy) {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }

    private var accessibilityLabel: String {
        if isSelectionMode {
            return isMergeSelected ? "Remove from selection" : "Select item"
        }
        return "Send \(item.contentType.displayName) via AirDrop"
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(isHovering || isSelected || isMergeSelected ? ClipDropDesignToken.Colors.rowHover : Color.clear)
    }

    @ViewBuilder
    private var contentPreview: some View {
        if item.contentType == .image,
           let imageData = item.imageData,
           let image = NSImage(data: imageData) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .accessibilityHidden(true)
        } else {
            Image(systemName: item.contentType.systemImageName)
                .symbolRenderingMode(.hierarchical)
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: ClipDropDesignToken.Size.leadingIcon, height: ClipDropDesignToken.Size.leadingIcon)
                .accessibilityHidden(true)
        }
    }
}

private extension ClipboardHistoryItem {
    var textForDisplay: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEditableText: Bool {
        contentType == .text || contentType == .formattedText || contentType == .link
    }
}
