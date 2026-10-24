import AppKit
import Carbon.HIToolbox
import KikiMenuBar
import KikiSettings
import XCTest
@testable import ClipDrop

@MainActor
final class ClipDropEntryPointTests: XCTestCase {
    func testShortcutSerializationAndDefaults() throws {
        let shortcut = ClipDropShortcut.defaultSendClipboard
        let roundTrip = try JSONDecoder().decode(ClipDropShortcut.self, from: JSONEncoder().encode(shortcut))

        XCTAssertEqual(roundTrip, shortcut)
        XCTAssertEqual(shortcut.displayText, "⌃⌥⌘C")
        XCTAssertEqual(ClipDropHotkeyAction.allCases.map(\.defaultsKey), [
            "ClipDrop.Shortcuts.sendClipboard",
            "ClipDrop.Shortcuts.showQRCode"
        ])
    }

    func testShortcutConflictAndRegistrationFailureAreExposed() throws {
        let defaults = makeDefaults()
        let registrar = FakeHotkeyRegistrar()
        let coordinator = ClipDropHotkeyCoordinator(
            defaults: defaults,
            registrar: registrar,
            sendClipboard: {},
            showQRCode: {}
        )
        let shared = ClipDropShortcut(keyCode: UInt32(kVK_ANSI_Q), modifiers: UInt32(cmdKey))

        coordinator.setShortcut(shared, for: .sendClipboard)
        coordinator.setShortcut(shared, for: .showQRCode)
        XCTAssertEqual(
            try JSONDecoder().decode(ClipDropShortcut.self, from: XCTUnwrap(defaults.data(forKey: ClipDropHotkeyAction.sendClipboard.defaultsKey))),
            shared
        )
        coordinator.start()

        XCTAssertEqual(
            coordinator.failureReason(for: .showQRCode),
            "This shortcut conflicts with Send Clipboard."
        )
        XCTAssertEqual(registrar.registeredActions, [.sendClipboard])

        registrar.failureForAction = .sendClipboard
        coordinator.setShortcut(.defaultSendClipboard, for: .sendClipboard)
        XCTAssertEqual(coordinator.failureReason(for: .sendClipboard), "This shortcut is already in use.")
        coordinator.setShortcut(nil, for: .sendClipboard)
        let reloaded = ClipDropHotkeyCoordinator(
            defaults: defaults,
            registrar: FakeHotkeyRegistrar(),
            sendClipboard: {},
            showQRCode: {}
        )
        XCTAssertNil(reloaded.shortcut(for: .sendClipboard), "A cleared shortcut must stay cleared after relaunch.")
        coordinator.stop()
    }

    func testServicesPasteboardMapsTextAndURLToPayload() throws {
        let textBoard = makePasteboard()
        textBoard.setString("A note", forType: .string)
        XCTAssertEqual(ClipDropServicesPayloadReader.payload(from: textBoard), .text("A note"))

        let urlBoard = makePasteboard()
        urlBoard.setString("https://example.com/path", forType: .string)
        XCTAssertEqual(
            ClipDropServicesPayloadReader.payload(from: urlBoard),
            .url(try XCTUnwrap(URL(string: "https://example.com/path")))
        )

        var sentPayloads: [ClipDropEntryPayload] = []
        let service = ClipDropServicesProvider { sentPayloads.append($0) }
        XCTAssertTrue(service.receive(textBoard))
        XCTAssertEqual(sentPayloads, [ClipDropEntryPayload.text("A note")])
    }

    func testIntentTextParameterMapsToPayload() {
        XCTAssertEqual(ClipDropIntentPayloadMapper.textPayload("Hello"), .text("Hello"))
    }

    func testDropPayloadConverterSupportsTextURLImageAndFileURLs() throws {
        let text = ClipDropDropPayloadConverter.payload(for: [.text("A note")])
        XCTAssertEqual(text, .text("A note"))

        let webURL = try XCTUnwrap(URL(string: "https://example.com"))
        XCTAssertEqual(ClipDropDropPayloadConverter.payload(for: [.url(webURL)]), .url(webURL))

        let image = NSImage(size: NSSize(width: 12, height: 12))
        guard case .image(let mappedImage)? = ClipDropDropPayloadConverter.payload(for: [.image(image)]) else {
            return XCTFail("Expected an image payload.")
        }
        XCTAssertTrue(mappedImage === image)

        let fileA = URL(fileURLWithPath: "/tmp/first.png")
        let fileB = URL(fileURLWithPath: "/tmp/second.pdf")
        XCTAssertEqual(
            ClipDropDropPayloadConverter.payload(for: [.fileURL(fileA), .fileURL(fileB)]),
            .files([fileA, fileB])
        )
    }

    func testDropHandlerAcceptsSupportedTypesAndSendsRouterPayload() async {
        XCTAssertEqual(
            Set(ClipDropDropHandler.acceptedPasteboardTypes),
            Set([
                NSPasteboard.PasteboardType.string,
                .URL,
                .fileURL,
                NSPasteboard.PasteboardType("public.png"),
                NSPasteboard.PasteboardType("public.tiff")
            ])
        )

        let pasteboard = makePasteboard()
        pasteboard.setString("Dropped note", forType: .string)
        var sentPayload: ClipDropPayload?
        let didSend = expectation(description: "The drop payload reaches the send route.")
        let handler = ClipDropDropHandler { payload in
            sentPayload = payload
            didSend.fulfill()
        }

        XCTAssertTrue(handler.handle(pasteboard))
        await fulfillment(of: [didSend], timeout: 1)
        XCTAssertEqual(sentPayload, .text("Dropped note"))
    }

    func testLaunchAtLoginModelKeepsApprovalPendingAsEnabled() {
        let service = FakeLaunchAtLoginService()
        let model = KikiLaunchAtLoginModel(service: service, notificationCenter: NotificationCenter())

        XCTAssertFalse(model.isOn)
        XCTAssertEqual(model.set(true), .requiresApproval)
        XCTAssertEqual(model.status, .requiresApproval)
        XCTAssertTrue(model.isOn)
    }

    func testContextMenuMapsAllRequestedActions() {
        var invoked: [String] = []
        let items = ClipDropContextMenuItems.make(
            sendClipboard: { invoked.append("send") },
            showQRCode: { invoked.append("qr") },
            openSettings: { invoked.append("settings") },
            quit: { invoked.append("quit") }
        )

        XCTAssertEqual(items.map { $0.title ?? "separator" }, [
            "Send Clipboard",
            "Show QR Code for Clipboard",
            "separator",
            "Settings…",
            "Quit"
        ])

        for item in items {
            switch item {
            case let .action(title, _, _, _, _, _, _, action):
                if ["Send Clipboard", "Show QR Code for Clipboard", "Quit"].contains(title) {
                    action()
                }
            case let .settings(_, action):
                action()
            default:
                break
            }
        }
        XCTAssertEqual(invoked, ["send", "qr", "settings", "quit"])
    }

    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ClipDropEntryPointTests.\(UUID().uuidString)")!
    }

    private func makePasteboard() -> NSPasteboard {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("ClipDropEntryPointTests.\(UUID().uuidString)"))
        pasteboard.clearContents()
        return pasteboard
    }
}

@MainActor
private final class FakeHotkeyRegistrar: ClipDropHotkeyRegistering {
    var registeredActions: [ClipDropHotkeyAction] = []
    var failureForAction: ClipDropHotkeyAction?

    func register(
        _ shortcut: ClipDropShortcut,
        for action: ClipDropHotkeyAction,
        handler: @escaping () -> Void
    ) throws {
        if failureForAction == action {
            throw ClipDropHotkeyRegistrationError.alreadyInUse
        }
        registeredActions.append(action)
    }

    func unregisterAll() {
        registeredActions.removeAll()
    }
}

private final class FakeLaunchAtLoginService: LaunchAtLoginService {
    var status: LaunchAtLoginStatus = .notRegistered

    func register() throws {
        status = .requiresApproval
    }

    func unregister() throws {
        status = .notRegistered
    }
}
