import SwiftUI

struct ClipDropRecentItemRow: View {
    let item: ClipboardHistoryItem
    @Binding var isExpanded: Bool
    let isSending: Bool
    let send: () -> Void
    let copy: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(item.contentType.tint.opacity(ClipDropDesignToken.Opacity.rowAccent))
                .frame(width: 2)
                .clipShape(Capsule())

            Image(systemName: item.contentType.systemImageName)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(item.contentType.tint)
                .frame(width: 18)

            DisclosureGroup(isExpanded: $isExpanded) {
                expandedContent
                    .padding(.top, 2)
            } label: {
                collapsedLabel
            }
            .disclosureGroupStyle(.automatic)

            Spacer(minLength: 6)

            HStack(spacing: 4) {
                ClipDropIconActionButton(
                    systemName: "doc.on.doc",
                    label: "Copy",
                    role: .secondary,
                    action: copy
                )

                ClipDropIconActionButton(
                    systemName: "paperplane.fill",
                    label: "Send via AirDrop",
                    role: .primary,
                    action: send
                )
                .disabled(isSending)
            }
        }
        .frame(minHeight: ClipDropDesignToken.Size.rowMinHeight)
        .help(isExpanded ? "Collapse" : "Expand")
    }

    @ViewBuilder
    private var collapsedLabel: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.contentType.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if !isExpanded {
                Text(item.textForDisplay)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        if let attributedText = item.swiftUIAttributedText {
            Text(attributedText)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        } else {
            Text(item.textForDisplay)
                .font(.body)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .textSelection(.enabled)
        }
    }
}

private extension ClipboardHistoryItem {
    var textForDisplay: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var swiftUIAttributedText: AttributedString? {
        guard let attributedText else {
            return nil
        }

        return try? AttributedString(attributedText, including: \.appKit)
    }
}
