import AppKit
import Carbon.HIToolbox
import KikiSettings
import SwiftUI

struct ClipDropShortcutSettingsSection: View {
    @ObservedObject var shortcutCoordinator: ClipDropHotkeyCoordinator
    @StateObject private var launchAtLoginModel = KikiLaunchAtLoginModel()

    var body: some View {
        Section {
            KikiSettingsLaunchAtLoginRow(
                title: "Open at Login",
                systemImage: "power",
                approvalNote: "Allow Clipboard Drop in System Settings › Login Items to finish enabling it.",
                openLoginItemsTitle: "Open Login Items",
                model: launchAtLoginModel
            )
        }

        Section {
            ForEach(ClipDropHotkeyAction.allCases, id: \.self) { action in
                ClipDropShortcutRow(shortcutCoordinator: shortcutCoordinator, action: action)
            }
        } header: {
            Text("Keyboard Shortcuts")
        } footer: {
            Text("Shortcuts work in any app while Clipboard Drop is running.")
        }
    }
}

private struct ClipDropShortcutRow: View {
    @ObservedObject var shortcutCoordinator: ClipDropHotkeyCoordinator
    let action: ClipDropHotkeyAction
    @State private var isRecording = false
    @State private var captureError: String?
#if DEBUG
    @State private var didApplyDebugRecordingState = false
#endif

    var body: some View {
        LabeledContent {
            ClipDropShortcutField(
                shortcut: shortcutCoordinator.shortcut(for: action),
                isRecording: isRecording,
                onBegin: {
                    captureError = nil
                    isRecording = true
                },
                onCapture: {
                    shortcutCoordinator.setShortcut($0, for: action)
                    captureError = nil
                    isRecording = false
                },
                onClear: {
                    shortcutCoordinator.setShortcut(nil, for: action)
                    captureError = nil
                    isRecording = false
                },
                onCancel: {
                    captureError = nil
                    isRecording = false
                },
                onInvalidShortcut: {
                    captureError = "Add a modifier key to use this shortcut."
                }
            )
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: ClipDropDesignToken.Settings.rowLabelSpacing) {
                Image(systemName: action == .sendClipboard ? "paperplane" : "qrcode")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(width: ClipDropDesignToken.Settings.rowIconWidth, alignment: .leading)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: ClipDropDesignToken.Settings.shortcutErrorSpacing) {
                    Text(action.title)
                    if let reason = captureError ?? shortcutCoordinator.failureReason(for: action) {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
#if DEBUG
        .onAppear {
            guard !didApplyDebugRecordingState,
                  action == .sendClipboard,
                  ProcessInfo.processInfo.arguments.contains("--clipdrop-debug-settings-recording") else {
                return
            }
            didApplyDebugRecordingState = true
            isRecording = true
        }
#endif
    }
}

private struct ClipDropShortcutField: View {
    let shortcut: ClipDropShortcut?
    let isRecording: Bool
    let onBegin: () -> Void
    let onCapture: (ClipDropShortcut) -> Void
    let onClear: () -> Void
    let onCancel: () -> Void
    let onInvalidShortcut: () -> Void

    var body: some View {
        ZStack {
            Button(action: onBegin) {
                Text(isRecording ? "Type Shortcut" : (shortcut?.displayText ?? "Record Shortcut"))
                    .font(shortcut == nil || isRecording ? .body : .system(.body, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(shortcut == nil || isRecording ? .secondary : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(ClipDropDesignToken.Settings.shortcutTextMinimumScaleFactor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.trailing, shortcut == nil ? 0 : ClipDropDesignToken.Settings.shortcutClearHitSize)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRecording ? "Type Shortcut" : (shortcut?.displayText ?? "Record Shortcut"))
            .accessibilityHint("Click to record a shortcut.")

            if shortcut != nil && !isRecording {
                HStack {
                    Spacer(minLength: 0)
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: ClipDropDesignToken.Settings.shortcutClearIconSize))
                            .foregroundStyle(.tertiary)
                            .frame(
                                width: ClipDropDesignToken.Settings.shortcutClearHitSize,
                                height: ClipDropDesignToken.Settings.shortcutClearHitSize
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear shortcut")
                    .onHover { isHovering in
                        if isHovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
            }
        }
        .frame(
            width: ClipDropDesignToken.Settings.shortcutFieldWidth,
            height: ClipDropDesignToken.Settings.shortcutFieldHeight
        )
        .background(
            RoundedRectangle(cornerRadius: ClipDropDesignToken.Settings.shortcutFieldCornerRadius)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay {
            RoundedRectangle(cornerRadius: ClipDropDesignToken.Settings.shortcutFieldCornerRadius)
                .strokeBorder(
                    isRecording ? Color.accentColor : Color(nsColor: .separatorColor),
                    lineWidth: isRecording
                        ? ClipDropDesignToken.Settings.shortcutRecordingBorderWidth
                        : ClipDropDesignToken.Settings.shortcutFieldBorderWidth
                )
        }
        .overlay {
            ClipDropShortcutKeyCapture(
                isRecording: isRecording,
                onCapture: onCapture,
                onClear: onClear,
                onCancel: onCancel,
                onInvalidShortcut: onInvalidShortcut
            )
        }
        .accessibilityElement(children: .contain)
    }
}

private struct ClipDropShortcutKeyCapture: NSViewRepresentable {
    let isRecording: Bool
    let onCapture: (ClipDropShortcut) -> Void
    let onClear: () -> Void
    let onCancel: () -> Void
    let onInvalidShortcut: () -> Void

    func makeNSView(context: Context) -> ShortcutKeyCaptureView {
        let view = ShortcutKeyCaptureView()
        update(view)
        return view
    }

    func updateNSView(_ view: ShortcutKeyCaptureView, context: Context) {
        update(view)
    }

    private func update(_ view: ShortcutKeyCaptureView) {
        view.isRecording = isRecording
        view.onCapture = onCapture
        view.onClear = onClear
        view.onCancel = onCancel
        view.onInvalidShortcut = onInvalidShortcut
        if isRecording {
            DispatchQueue.main.async {
                view.window?.makeFirstResponder(view)
            }
        } else if view.window?.firstResponder === view {
            view.window?.makeFirstResponder(nil)
        }
    }
}

@MainActor
private final class ShortcutKeyCaptureView: NSView {
    var isRecording = false
    var onCapture: ((ClipDropShortcut) -> Void)?
    var onClear: (() -> Void)?
    var onCancel: (() -> Void)?
    var onInvalidShortcut: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == UInt16(kVK_Escape) {
            onCancel?()
            return
        }
        if event.keyCode == UInt16(kVK_Delete), !Self.hasModifier(event.modifierFlags) {
            onClear?()
            return
        }
        guard let shortcut = ClipDropShortcut(event: event) else {
            onInvalidShortcut?()
            NSSound.beep()
            return
        }
        onCapture?(shortcut)
    }

    private static func hasModifier(_ flags: NSEvent.ModifierFlags) -> Bool {
        flags.contains(.control) || flags.contains(.option) || flags.contains(.shift) || flags.contains(.command)
    }
}
