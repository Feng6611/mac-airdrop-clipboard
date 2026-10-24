import AppKit
import Carbon.HIToolbox
import KikiSettings
import SwiftUI

struct ClipDropShortcutSettingsSection: View {
    @ObservedObject var shortcutCoordinator: ClipDropHotkeyCoordinator
    @StateObject private var launchAtLoginModel = KikiLaunchAtLoginModel()

    var body: some View {
        Section("Keyboard Shortcuts") {
            ForEach(ClipDropHotkeyAction.allCases, id: \.self) { action in
                ClipDropShortcutRow(shortcutCoordinator: shortcutCoordinator, action: action)
            }
            KikiSettingsHelperText("Click a shortcut to record it. Press Escape to cancel.")
        }

        Section("Startup") {
            KikiSettingsLaunchAtLoginRow(
                title: "Open at Login",
                approvalNote: "Allow Clipboard Drop in System Settings › Login Items to finish enabling it.",
                openLoginItemsTitle: "Open Login Items",
                model: launchAtLoginModel
            )
        }
    }
}

private struct ClipDropShortcutRow: View {
    @ObservedObject var shortcutCoordinator: ClipDropHotkeyCoordinator
    let action: ClipDropHotkeyAction
    @State private var isRecording = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(action.title)
                Spacer()
                ClipDropShortcutCaptureButton(
                    shortcut: shortcutCoordinator.shortcut(for: action),
                    isRecording: isRecording,
                    onBegin: { isRecording = true },
                    onCapture: {
                        shortcutCoordinator.setShortcut($0, for: action)
                        isRecording = false
                    },
                    onCancel: { isRecording = false }
                )
                Button("Clear") {
                    shortcutCoordinator.setShortcut(nil, for: action)
                }
                .disabled(shortcutCoordinator.shortcut(for: action) == nil)
            }

            if let reason = shortcutCoordinator.failureReason(for: action) {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct ClipDropShortcutCaptureButton: NSViewRepresentable {
    let shortcut: ClipDropShortcut?
    let isRecording: Bool
    let onBegin: () -> Void
    let onCapture: (ClipDropShortcut) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onBegin: onBegin)
    }

    func makeNSView(context: Context) -> NSButton {
        let button = RecordingShortcutButton(title: "Record Shortcut", target: context.coordinator, action: #selector(Coordinator.beginRecording))
        button.bezelStyle = .rounded
        button.controlSize = .small
        button.setAccessibilityLabel("Record Shortcut")
        button.onCapture = onCapture
        button.onCancel = onCancel
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        guard let button = button as? RecordingShortcutButton else { return }
        context.coordinator.onBegin = onBegin
        button.isRecording = isRecording
        button.title = isRecording ? "Press Shortcut" : (shortcut?.displayText ?? "Record Shortcut")
        button.onCapture = onCapture
        button.onCancel = onCancel
    }

    final class Coordinator: NSObject {
        var onBegin: () -> Void

        init(onBegin: @escaping () -> Void) {
            self.onBegin = onBegin
        }

        @objc func beginRecording(_ sender: Any?) {
            onBegin()
        }
    }
}

@MainActor
private final class RecordingShortcutButton: NSButton {
    var isRecording = false
    var onCapture: ((ClipDropShortcut) -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        if event.keyCode == UInt16(kVK_Escape) {
            isRecording = false
            title = "Record Shortcut"
            onCancel?()
            return
        }
        guard let shortcut = ClipDropShortcut(event: event) else {
            NSSound.beep()
            return
        }
        isRecording = false
        onCapture?(shortcut)
    }
}
