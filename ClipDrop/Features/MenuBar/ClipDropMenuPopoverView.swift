import KikiCommerceCore
import SwiftUI

struct ClipDropMenuPopoverView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedItemID: ClipboardHistoryItem.ID?
    let config: ClipDropAppConfig
    @ObservedObject var controller: ClipDropController
    @ObservedObject var accessManager: KikiAccessManager
    let actions: ClipDropPopoverActions

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, ClipDropDesignToken.Spacing.page)
                .padding(.vertical, ClipDropDesignToken.Spacing.headerVertical)

            Divider()

            clipboardContent

            Divider()

            footer
                .padding(.horizontal, ClipDropDesignToken.Spacing.page)
                .padding(.vertical, ClipDropDesignToken.Spacing.footerVertical)
        }
        .frame(
            width: ClipDropDesignToken.Size.popoverWidth,
            height: ClipDropDesignToken.Size.popoverHeight
        )
        .background(keyboardActions)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "paperplane.fill")
                .font(.system(size: ClipDropDesignToken.Size.brandMark, weight: .semibold))
                .foregroundStyle(ClipDropDesignToken.Colors.brand)
                .accessibilityHidden(true)

            Text(config.appName)
                .font(.headline)

            Spacer()

            overflowMenu
        }
    }

    private var overflowMenu: some View {
        Menu {
            if !controller.historyItems.isEmpty {
                Button(role: .destructive, action: actions.clearHistory) {
                    Label("Clear History…", systemImage: "trash")
                }
                Divider()
            }

            Button(action: actions.openSettings) {
                Label("Settings…", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: .command)

            Button(action: actions.quit) {
                Label("Quit \(config.appName)", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
        }
        .menuStyle(.button)
        .buttonStyle(.borderless)
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("More actions")
        .help("More actions")
    }

    // MARK: Clipboard content

    private var clipboardContent: some View {
        Group {
            if controller.historyItems.isEmpty {
                emptyClipboardState
            } else {
                clipboardItemsList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(currentClipboardAnimation, value: controller.historyItems.first?.id)
    }

    private var emptyClipboardState: some View {
        VStack(spacing: 6) {
            Image(systemName: "doc.on.clipboard")
                .font(.title2)
                .foregroundStyle(.tertiary)

            Text("Clipboard is empty")
                .font(.subheadline.weight(.medium))

            Text("Copy text or a link — it shows up here, ready to AirDrop.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    private var clipboardItemsList: some View {
        List {
            ForEach(controller.historyItems) { item in
                ClipDropRecentItemRow(
                    item: item,
                    isSending: controller.isSending,
                    isSelected: selectedItemID == item.id,
                    send: { selectAndSend(item) },
                    copy: { selectAndCopy(item) }
                )
                .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .onAppear(perform: synchronizeSelection)
        .onChange(of: controller.historyItems.map(\.id)) { _ in
            synchronizeSelection()
        }
    }

    private var currentClipboardAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.16)
            : .spring(response: 0.32, dampingFraction: 1)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 8) {
            if showsAccessButton {
                Button(action: actions.openPaywall) {
                    Label(accessButtonTitle, systemImage: "sparkles")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(ClipDropDesignToken.Colors.brand)
                .help(accessButtonHelp)
            }

            Spacer()

            Button(action: actions.openSettings) {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("Open settings (⌘,)")
        }
    }

    // MARK: Keyboard

    /// Zero-size default/⌘C actions bound to the current selection so the popover
    /// supports Return (send) and ⌘C (copy) while it is the key window.
    private var keyboardActions: some View {
        ZStack {
            Button(action: sendSelectedItem) {}
                .keyboardShortcut(.defaultAction)
            Button(action: copySelectedItem) {}
                .keyboardShortcut("c", modifiers: .command)
            Button(action: selectPreviousItem) {}
                .keyboardShortcut(.upArrow, modifiers: [])
            Button(action: selectNextItem) {}
                .keyboardShortcut(.downArrow, modifiers: [])
        }
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }

    private var selectedItem: ClipboardHistoryItem? {
        guard let selectedItemID else { return nil }
        return controller.historyItems.first { $0.id == selectedItemID }
    }

    private func sendSelectedItem() {
        guard !controller.isSending, let selectedItem else { return }
        actions.sendHistoryItem(selectedItem)
    }

    private func copySelectedItem() {
        guard let selectedItem else { return }
        actions.copyHistoryItem(selectedItem)
    }

    private func selectPreviousItem() {
        moveSelection(by: -1)
    }

    private func selectNextItem() {
        moveSelection(by: 1)
    }

    private func selectAndSend(_ item: ClipboardHistoryItem) {
        selectedItemID = item.id
        actions.sendHistoryItem(item)
    }

    private func selectAndCopy(_ item: ClipboardHistoryItem) {
        selectedItemID = item.id
        actions.copyHistoryItem(item)
    }

    private func synchronizeSelection() {
        let itemIDs = controller.historyItems.map(\.id)
        if let selectedItemID, itemIDs.contains(selectedItemID) {
            return
        }
        selectedItemID = nil
    }

    private func moveSelection(by offset: Int) {
        let itemIDs = controller.historyItems.map(\.id)
        guard !itemIDs.isEmpty else {
            selectedItemID = nil
            return
        }

        guard let selectedItemID,
              let currentIndex = itemIDs.firstIndex(of: selectedItemID) else {
            self.selectedItemID = offset < 0 ? itemIDs.last : itemIDs.first
            return
        }

        let nextIndex = min(max(currentIndex + offset, itemIDs.startIndex), itemIDs.index(before: itemIDs.endIndex))
        self.selectedItemID = itemIDs[nextIndex]
    }

    private var showsAccessButton: Bool {
        guard !accessManager.status.isPro else {
            return false
        }
        return accessManager.status.isActive || accessManager.readiness == .ready
    }

    private var accessButtonTitle: String {
        switch accessManager.status {
        case .notStarted:
            return "Try Pro"
        case .trial(.time(let daysRemaining, _)):
            return "Trial · \(daysRemaining)d left"
        case .trial(.usage):
            return "Trial active"
        case .expired:
            return "Unlock Pro"
        case .pro:
            return "Pro"
        }
    }

    private var accessButtonHelp: String {
        switch accessManager.status {
        case .notStarted:
            return "Start a two-day trial or choose a lifetime unlock"
        case .trial:
            return "View lifetime Pro options"
        case .expired:
            return "Choose a lifetime Pro unlock"
        case .pro:
            return "View Pro access"
        }
    }
}
