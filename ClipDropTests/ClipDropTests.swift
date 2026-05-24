import AppKit
import XCTest
@testable import ClipDrop

@MainActor
final class ClipDropTests: XCTestCase {
    func testRecentClipboardPreviewsCollapseWhitespace() {
        let item = ClipboardHistoryItem(
            id: UUID(),
            text: "hello\nworld\tfrom ClipDrop",
            contentType: .text,
            createdAt: Date()
        )

        XCTAssertEqual(item.preview, "hello world from ClipDrop")
    }

    func testRecentClipboardPreviewsTruncateAtSeventyCharacters() {
        let item = ClipboardHistoryItem(
            id: UUID(),
            text: String(repeating: "a", count: 71),
            contentType: .text,
            createdAt: Date()
        )

        XCTAssertEqual(item.preview.count, 70)
        XCTAssertTrue(item.preview.hasSuffix("..."))
    }

    func testHistoryDeduplicatesAndCapsItems() {
        let store = ClipboardHistoryStore(
            pasteboard: NSPasteboard(name: NSPasteboard.Name(UUID().uuidString)),
            maxItemCount: 3
        )

        store.record("one")
        store.record("two")
        store.record("three")
        store.record("two")
        store.record("four")

        XCTAssertEqual(store.items.map(\.text), ["four", "two", "three"])
    }

    func testHistoryRecordsContentTypes() {
        let store = ClipboardHistoryStore(
            pasteboard: NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        )

        store.record("plain", contentType: .text)
        store.record("https://example.com", contentType: .link)
        store.record("rich", contentType: .formattedText)

        XCTAssertEqual(store.items.map(\.contentType), [.formattedText, .link, .text])
        XCTAssertEqual(store.items.map(\.contentType.displayName), ["Text (Formatted)", "Link", "Text"])
    }

    func testClearRecentItemsSuppressesCurrentPasteboardUntilItChanges() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()
        pasteboard.setString("secret code", forType: .string)

        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        store.syncCurrentClipboard()
        XCTAssertEqual(store.items.map(\.text), ["secret code"])

        store.clear()
        store.syncCurrentClipboard()
        XCTAssertTrue(store.items.isEmpty)

        pasteboard.clearContents()
        pasteboard.setString("new code", forType: .string)
        store.syncCurrentClipboard()
        XCTAssertEqual(store.items.map(\.text), ["new code"])
    }

    func testCopyHistoryItemWritesToPasteboard() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        let item = ClipboardHistoryItem(id: UUID(), text: "copy me", contentType: .formattedText, createdAt: Date())

        try store.copy(item)

        XCTAssertEqual(pasteboard.string(forType: .string), "copy me")
        XCTAssertEqual(store.items.map(\.text), ["copy me"])
        XCTAssertEqual(store.items.map(\.contentType), [.formattedText])
    }

    func testClipboardContentTypeClassifiesHttpLinks() {
        XCTAssertEqual(
            ClipboardContentType.classify(text: "  https://example.com/path?q=one  ", hasFormattedRepresentation: true),
            .link
        )
        XCTAssertEqual(
            ClipboardContentType.classify(text: "ftp://example.com/file", hasFormattedRepresentation: false),
            .text
        )
    }

    func testClipboardContentTypeClassifiesFormattedText() {
        XCTAssertEqual(
            ClipboardContentType.classify(text: "formatted", hasFormattedRepresentation: true),
            .formattedText
        )
    }

    func testPlainAttributedClipboardIsRecordedAsText() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()
        pasteboard.writeObjects([NSAttributedString(string: "plain attributed")])

        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        store.syncCurrentClipboard()

        XCTAssertEqual(store.items.map(\.contentType), [.text])
        XCTAssertNil(store.items.first?.attributedText)
    }

    func testStyledAttributedClipboardIsRecordedAsFormattedText() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        let attributedString = NSMutableAttributedString(string: "styled text")
        attributedString.addAttribute(
            .font,
            value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize),
            range: NSRange(location: 0, length: 6)
        )
        pasteboard.clearContents()
        pasteboard.writeObjects([attributedString])

        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        store.syncCurrentClipboard()

        XCTAssertEqual(store.items.map(\.contentType), [.formattedText])
        XCTAssertEqual(store.items.first?.attributedText?.string, "styled text")
    }

    func testEmptyClipboardSendFails() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()
        let sender = ClipboardSenderService(
            pasteboard: pasteboard,
            sharingProvider: FakeClipboardSharingProvider()
        )

        XCTAssertThrowsError(try sender.sendClipboardViaAirDrop()) { error in
            XCTAssertEqual(error as? ClipboardSenderError, .emptyClipboard)
        }
    }

    func testHttpURLsAreNormalizedIntoTextFile() throws {
        let fakeSharing = FakeClipboardSharingProvider()
        let sender = ClipboardSenderService(
            sharingProvider: fakeSharing,
            now: { Date(timeIntervalSince1970: 0) }
        )

        let result = try sender.sendTextViaAirDrop("  https://example.com/path?q=one  ")

        XCTAssertEqual(result.kind, .url)
        XCTAssertEqual(try String(contentsOf: result.fileURL, encoding: .utf8), "https://example.com/path?q=one")
        XCTAssertEqual(fakeSharing.performedURLs, [result.fileURL])
    }

    func testTextCanBeSentAsMarkdownFile() throws {
        let sender = ClipboardSenderService(
            sharingProvider: FakeClipboardSharingProvider(),
            preferences: {
                ClipDropSendPreferences(textFileFormat: .markdown)
            }
        )

        let result = try sender.sendTextViaAirDrop("# Notes")

        XCTAssertEqual(result.kind, .text)
        XCTAssertEqual(result.fileURL.pathExtension, "md")
        XCTAssertEqual(try String(contentsOf: result.fileURL, encoding: .utf8), "# Notes")
    }

    func testHttpURLsCanBeSentAsURLFiles() throws {
        let sender = ClipboardSenderService(
            sharingProvider: FakeClipboardSharingProvider(),
            preferences: {
                ClipDropSendPreferences(urlSendFormat: .urlFile)
            }
        )

        let result = try sender.sendTextViaAirDrop("https://example.com/path?q=one")

        XCTAssertEqual(result.kind, .url)
        XCTAssertEqual(result.fileURL.pathExtension, "url")
        XCTAssertEqual(
            try String(contentsOf: result.fileURL, encoding: .utf8),
            "[InternetShortcut]\nURL=https://example.com/path?q=one\n"
        )
    }

    func testNonHttpURLsAreSentAsPlainText() throws {
        let sender = ClipboardSenderService(sharingProvider: FakeClipboardSharingProvider())

        let result = try sender.sendTextViaAirDrop("ftp://example.com/file")

        XCTAssertEqual(result.kind, .text)
        XCTAssertEqual(try String(contentsOf: result.fileURL, encoding: .utf8), "ftp://example.com/file")
    }

    func testSenderRemovesPreviousTemporaryFilesOnStartup() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "ClipboardDrop",
            isDirectory: true
        )
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        let staleFileURL = temporaryDirectory.appendingPathComponent("stale.txt")
        try "old clipboard".write(to: staleFileURL, atomically: true, encoding: .utf8)

        _ = ClipboardSenderService(sharingProvider: FakeClipboardSharingProvider())

        XCTAssertFalse(FileManager.default.fileExists(atPath: staleFileURL.path))
    }

    func testControllerKeepsHistoryItemTypeAfterCopy() {
        let controller = ClipDropController(
            sender: ClipboardSenderService(sharingProvider: FakeClipboardSharingProvider()),
            historyStore: ClipboardHistoryStore(pasteboard: NSPasteboard(name: NSPasteboard.Name(UUID().uuidString)))
        )
        let item = ClipboardHistoryItem(id: UUID(), text: "hello", contentType: .link, createdAt: Date())
        controller.copyHistoryItem(item)

        XCTAssertEqual(controller.statusSummary, "Copied")
        XCTAssertEqual(controller.historyItems.map(\.text), ["hello"])
        XCTAssertEqual(controller.historyItems.map(\.contentType), [.link])
    }

    func testDefaultHistoryLimitMatchesAppConfig() {
        XCTAssertEqual(ClipDropAppConfig.default.maxRecentItems, 10)

        let store = ClipboardHistoryStore(
            pasteboard: NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        )
        for index in 0..<12 {
            store.record("item \(index)")
        }

        XCTAssertEqual(store.items.count, 10)
        XCTAssertEqual(store.items.first?.text, "item 11")
        XCTAssertEqual(store.items.last?.text, "item 2")
    }

    func testVersionSummaryUsesStableFormat() {
        XCTAssertEqual(
            ClipDropController.versionSummary(version: "1.2.3", build: "45"),
            "Version 1.2.3 (45)"
        )
    }

}

@MainActor
private final class FakeClipboardSharingProvider: ClipboardSharingProviding {
    private(set) var performedURLs: [URL] = []
    var shouldSucceed = true

    func performAirDrop(with fileURL: URL) -> Bool {
        performedURLs.append(fileURL)
        return shouldSucceed
    }
}
