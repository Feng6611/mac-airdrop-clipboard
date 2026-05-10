import KikiDesign
import SwiftUI

struct ClipDropMenuPopoverView: View {
    let config: ClipDropAppConfig
    @ObservedObject var controller: ClipDropController
    let actions: ClipDropPopoverActions
    @State private var expandedItemIDs: Set<ClipboardHistoryItem.ID> = []

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, ClipDropDesignToken.Spacing.page)
                .padding(.vertical, ClipDropDesignToken.Spacing.headerVertical)

            Divider()
                .opacity(ClipDropDesignToken.Opacity.divider)

            recentList

            Divider()
                .opacity(ClipDropDesignToken.Opacity.divider)

            footer
                .padding(.horizontal, ClipDropDesignToken.Spacing.footerHorizontal)
                .padding(.vertical, ClipDropDesignToken.Spacing.footerVertical)
        }
        .frame(
            width: ClipDropDesignToken.Size.popoverWidth,
            height: ClipDropDesignToken.Size.popoverHeight
        )
        .kikiWindowMaterialBackground(
            material: .regularMaterial,
            tint: Color(nsColor: .windowBackgroundColor),
            tintOpacity: ClipDropDesignToken.Opacity.windowTint
        )
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "paperplane.fill")
                .symbolRenderingMode(.palette)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(
                    ClipDropDesignToken.Colors.brandColor,
                    ClipDropDesignToken.Colors.brandColor.opacity(0.72)
                )
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(config.appName)
                    .font(.headline)

                Text(controller.statusSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            ClipDropIconActionButton(
                systemName: "paperplane.fill",
                label: "Send current clipboard via AirDrop",
                role: .primary,
                action: actions.sendClipboard
            )
            .disabled(controller.isSending)
        }
    }

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Recent")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, ClipDropDesignToken.Spacing.page)
            .padding(.top, ClipDropDesignToken.Spacing.sectionTop)
            .padding(.bottom, 6)

            if controller.historyItems.isEmpty {
                emptyRecentState
            } else {
                recentItemsList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var emptyRecentState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.tertiary)

            Text("No recent clipboard")
                .font(.subheadline.weight(.medium))

            Text("Copy text or a link to show it here.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var recentItemsList: some View {
        List {
            ForEach(controller.historyItems) { item in
                ClipDropRecentItemRow(
                    item: item,
                    isExpanded: Binding(
                        get: { expandedItemIDs.contains(item.id) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedItemIDs.insert(item.id)
                            } else {
                                expandedItemIDs.remove(item.id)
                            }
                        }
                    ),
                    isSending: controller.isSending,
                    send: { actions.sendHistoryItem(item) },
                    copy: { actions.copyHistoryItem(item) }
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 14, bottom: 6, trailing: 12))
                .listRowBackground(Color.clear)
            }
        }
        .id(controller.historyItems.first?.id)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                actions.openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help("Open settings")

            Spacer()

            Button {
                actions.quit()
            } label: {
                Label("Quit", systemImage: "power")
                    .labelStyle(.iconOnly)
                    .frame(width: 26, height: 24)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .help("Quit \(config.appName)")
        }
    }
}
