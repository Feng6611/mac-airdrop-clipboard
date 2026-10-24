import Combine
import Foundation

@MainActor
final class ClipDropHotkeyCoordinator: ObservableObject {
    @Published private(set) var shortcuts: [ClipDropHotkeyAction: ClipDropShortcut]
    @Published private(set) var failureReasons: [ClipDropHotkeyAction: String] = [:]

    private let defaults: UserDefaults
    private let registrar: any ClipDropHotkeyRegistering
    private let sendClipboard: () -> Void
    private let showQRCode: () -> Void
    private var isStarted = false

    init(
        defaults: UserDefaults = .standard,
        registrar: (any ClipDropHotkeyRegistering)? = nil,
        sendClipboard: @escaping () -> Void,
        showQRCode: @escaping () -> Void
    ) {
        self.defaults = defaults
        self.registrar = registrar ?? ClipDropCarbonHotkeyRegistrar()
        self.sendClipboard = sendClipboard
        self.showQRCode = showQRCode
        self.shortcuts = Self.loadShortcuts(from: defaults)
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        updateRegistrations()
    }

    func stop() {
        guard isStarted else { return }
        registrar.unregisterAll()
        failureReasons = [:]
        isStarted = false
    }

    func shortcut(for action: ClipDropHotkeyAction) -> ClipDropShortcut? {
        shortcuts[action]
    }

    func failureReason(for action: ClipDropHotkeyAction) -> String? {
        failureReasons[action]
    }

    func setShortcut(_ shortcut: ClipDropShortcut?, for action: ClipDropHotkeyAction) {
        shortcuts[action] = shortcut
        if let shortcut, let data = try? JSONEncoder().encode(shortcut) {
            defaults.set(data, forKey: action.defaultsKey)
            defaults.removeObject(forKey: Self.disabledDefaultsKey(for: action))
        } else {
            defaults.removeObject(forKey: action.defaultsKey)
            defaults.set(true, forKey: Self.disabledDefaultsKey(for: action))
        }
        if isStarted {
            updateRegistrations()
        }
    }

    private func updateRegistrations() {
        registrar.unregisterAll()
        failureReasons = [:]
        var registered: [ClipDropShortcut: ClipDropHotkeyAction] = [:]

        for action in ClipDropHotkeyAction.allCases {
            guard let shortcut = shortcuts[action] else { continue }
            if let existingAction = registered[shortcut] {
                failureReasons[action] = "This shortcut is already used for \(existingAction.title)."
                continue
            }

            do {
                try registrar.register(shortcut, for: action) { [weak self] in
                    self?.perform(action)
                }
                registered[shortcut] = action
            } catch let error as ClipDropHotkeyRegistrationError {
                failureReasons[action] = error.userMessage
            } catch {
                failureReasons[action] = "This shortcut couldn’t be registered. Try another."
            }
        }
    }

    private func perform(_ action: ClipDropHotkeyAction) {
        switch action {
        case .sendClipboard:
            sendClipboard()
        case .showQRCode:
            showQRCode()
        }
    }

    private static func loadShortcuts(from defaults: UserDefaults) -> [ClipDropHotkeyAction: ClipDropShortcut] {
        var result: [ClipDropHotkeyAction: ClipDropShortcut] = [:]
        for action in ClipDropHotkeyAction.allCases {
            if defaults.bool(forKey: disabledDefaultsKey(for: action)) {
                continue
            }
            if let data = defaults.data(forKey: action.defaultsKey),
               let shortcut = try? JSONDecoder().decode(ClipDropShortcut.self, from: data) {
                result[action] = shortcut
                continue
            }
            if action == .sendClipboard { result[action] = .defaultSendClipboard }
        }
        return result
    }

    private static func disabledDefaultsKey(for action: ClipDropHotkeyAction) -> String {
        "\(action.defaultsKey).disabled"
    }
}
