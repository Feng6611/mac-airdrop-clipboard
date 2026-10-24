import AppKit
import Carbon.HIToolbox
import Foundation

enum ClipDropHotkeyAction: String, CaseIterable, Codable, Hashable {
    case sendClipboard = "sendClipboard"
    case showQRCode = "showQRCode"

    var title: String {
        switch self {
        case .sendClipboard:
            return "Send Clipboard"
        case .showQRCode:
            return "Show QR Code for Clipboard"
        }
    }

    var defaultsKey: String {
        "ClipDrop.Shortcuts.\(rawValue)"
    }
}

struct ClipDropShortcut: Codable, Equatable, Hashable {
    let keyCode: UInt32
    let modifiers: UInt32

    static let defaultSendClipboard = ClipDropShortcut(
        keyCode: UInt32(kVK_ANSI_C),
        modifiers: UInt32(controlKey | optionKey | cmdKey)
    )

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(event: NSEvent) {
        let flags = event.modifierFlags
        var carbonModifiers: UInt32 = 0
        if flags.contains(.control) { carbonModifiers |= UInt32(controlKey) }
        if flags.contains(.option) { carbonModifiers |= UInt32(optionKey) }
        if flags.contains(.shift) { carbonModifiers |= UInt32(shiftKey) }
        if flags.contains(.command) { carbonModifiers |= UInt32(cmdKey) }
        guard carbonModifiers != 0 else { return nil }
        self.init(keyCode: UInt32(event.keyCode), modifiers: carbonModifiers)
    }

    var displayText: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(Self.keyNames[keyCode] ?? "Key \(keyCode)")
        return parts.joined()
    }

    private static let keyNames: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9", UInt32(kVK_Space): "Space",
        UInt32(kVK_Return): "Return", UInt32(kVK_Tab): "Tab", UInt32(kVK_Delete): "Delete",
        UInt32(kVK_ForwardDelete): "Forward Delete", UInt32(kVK_Escape): "Escape",
        UInt32(kVK_LeftArrow): "←", UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑", UInt32(kVK_DownArrow): "↓"
    ]
}

enum ClipDropHotkeyRegistrationError: Error, Equatable {
    case alreadyInUse
    case failed(OSStatus)

    var userMessage: String {
        switch self {
        case .alreadyInUse:
            return "This shortcut is already in use."
        case .failed(let status):
            return "macOS could not register this shortcut (OSStatus \(status))."
        }
    }
}

@MainActor
protocol ClipDropHotkeyRegistering: AnyObject {
    func register(
        _ shortcut: ClipDropShortcut,
        for action: ClipDropHotkeyAction,
        handler: @escaping () -> Void
    ) throws
    func unregisterAll()
}

@MainActor
final class ClipDropCarbonHotkeyRegistrar: ClipDropHotkeyRegistering {
    private var eventHandler: EventHandlerRef?
    private var registrations: [UInt32: EventHotKeyRef] = [:]
    private var handlers: [UInt32: () -> Void] = [:]

    func register(
        _ shortcut: ClipDropShortcut,
        for action: ClipDropHotkeyAction,
        handler: @escaping () -> Void
    ) throws {
        try installEventHandlerIfNeeded()
        let identifier = Self.identifier(for: action)
        let hotKeyID = EventHotKeyID(signature: clipDropHotkeySignature, id: identifier)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard status == noErr, let hotKeyRef else {
            if status == -9878 {
                throw ClipDropHotkeyRegistrationError.alreadyInUse
            }
            throw ClipDropHotkeyRegistrationError.failed(status)
        }
        registrations[identifier] = hotKeyRef
        handlers[identifier] = handler
    }

    func unregisterAll() {
        for hotKey in registrations.values {
            UnregisterEventHotKey(hotKey)
        }
        registrations.removeAll()
        handlers.removeAll()
    }

    fileprivate func deliver(identifier: UInt32) {
        handlers[identifier]?()
    }

    private func installEventHandlerIfNeeded() throws {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            clipDropHotkeyEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        guard status == noErr else {
            throw ClipDropHotkeyRegistrationError.failed(status)
        }
    }

    private static func identifier(for action: ClipDropHotkeyAction) -> UInt32 {
        switch action {
        case .sendClipboard: return 1
        case .showQRCode: return 2
        }
    }

}

private let clipDropHotkeySignature = OSType(0x43445031)

private func clipDropHotkeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return noErr }
    var hotKeyID = EventHotKeyID(signature: 0, id: 0)
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr, hotKeyID.signature == clipDropHotkeySignature else {
        return noErr
    }
    let identifier = hotKeyID.id
    let registrar = Unmanaged<ClipDropCarbonHotkeyRegistrar>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in
        registrar.deliver(identifier: identifier)
    }
    return noErr
}
