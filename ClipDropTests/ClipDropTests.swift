import AppKit
import Foundation
import XCTest
@testable import ClipDrop

@MainActor
final class ClipDropTests: XCTestCase {
    func testRecentClipboardPreviewsCollapseWhitespace() {
        let item = historyItem("hello\nworld\tfrom ClipDrop")
        XCTAssertEqual(item.preview, "hello world from ClipDrop")
    }

    func testRecentClipboardPreviewsTruncateAtSeventyCharacters() {
        let item = historyItem(String(repeating: "a", count: 71))
        XCTAssertEqual(item.preview.count, 70)
        XCTAssertTrue(item.preview.hasSuffix("..."))
    }

    func testHistoryDeduplicatesAndCapsItems() {
        let store = historyStore(maxItemCount: 3)
        store.record("one")
        store.record("two")
        store.record("three")
        store.record("two")
        store.record("four")
        XCTAssertEqual(store.items.map(\.text), ["four", "two", "three"])
    }

    func testHistoryRecordsContentTypes() {
        let store = historyStore()
        store.record("plain", contentType: .text)
        store.record("https://example.com", contentType: .link)
        store.record("rich", contentType: .formattedText)
        XCTAssertEqual(store.items.map(\.contentType), [.formattedText, .link, .text])
        XCTAssertEqual(store.items.map(\.contentType.displayName), ["Text (Formatted)", "Link", "Text"])
    }

    func testClearRecentItemsSuppressesCurrentPasteboardUntilItChanges() {
        let pasteboard = namedPasteboard()
        pasteboard.setString("secret code", forType: .string)
        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        store.syncCurrentClipboard()
        XCTAssertEqual(store.items.map(\.text), ["secret code"])
        XCTAssertEqual(store.currentItem?.text, "secret code")

        store.clear()
        store.syncCurrentClipboard()
        XCTAssertTrue(store.items.isEmpty)
        XCTAssertNil(store.currentItem)

        pasteboard.clearContents()
        pasteboard.setString("new code", forType: .string)
        store.syncCurrentClipboard()
        XCTAssertEqual(store.items.map(\.text), ["new code"])
        XCTAssertEqual(store.currentItem?.text, "new code")
    }

    func testCopyHistoryItemWritesToPasteboard() throws {
        let pasteboard = namedPasteboard()
        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        let item = historyItem("copy me", contentType: .formattedText)
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
        XCTAssertEqual(ClipboardContentType.classify(text: "ftp://example.com/file", hasFormattedRepresentation: false), .text)
    }

    func testClipboardContentTypeClassifiesFormattedText() {
        XCTAssertEqual(ClipboardContentType.classify(text: "formatted", hasFormattedRepresentation: true), .formattedText)
    }

    func testPlainAttributedClipboardIsRecordedAsText() {
        let pasteboard = namedPasteboard()
        pasteboard.writeObjects([NSAttributedString(string: "plain attributed")])
        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        store.syncCurrentClipboard()
        XCTAssertEqual(store.items.map(\.contentType), [.text])
        XCTAssertNil(store.items.first?.attributedText)
    }

    func testStyledAttributedClipboardIsRecordedAsFormattedText() {
        let pasteboard = namedPasteboard()
        let attributedString = NSMutableAttributedString(string: "styled text")
        attributedString.addAttribute(
            .font,
            value: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize),
            range: NSRange(location: 0, length: 6)
        )
        pasteboard.writeObjects([attributedString])
        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        store.syncCurrentClipboard()
        XCTAssertEqual(store.items.map(\.contentType), [.formattedText])
        XCTAssertEqual(store.items.first?.attributedText?.string, "styled text")
    }

    func testEmptyTextSendFailsBeforeOpeningAirDrop() async {
        let provider = FakeClipboardSharingProvider()
        let sender = makeSender(provider: provider)
        let outcome = await sender.send(.text(" \n\t"))
        XCTAssertEqual(outcome, .failure(.emptyClipboard))
        XCTAssertTrue(provider.performedURLs.isEmpty)
    }

    func testTextCanBeSentAsMarkdownFile() async {
        let provider = FakeClipboardSharingProvider()
        let sender = makeSender(provider: provider, preferences: .init(textFileFormat: .markdown))
        let outcome = await sender.send(.text("# Notes"))
        guard case .success(let receipt) = outcome else { return XCTFail("Expected a confirmed share") }
        XCTAssertEqual(receipt.kind, .text)
        XCTAssertEqual(URL(fileURLWithPath: receipt.fileName).pathExtension, "md")
        XCTAssertEqual(provider.capturedContents, ["# Notes"])
    }

    func testURLCanBeSentAsURLFile() async {
        let provider = FakeClipboardSharingProvider()
        let sender = makeSender(provider: provider, preferences: .init(urlSendFormat: .urlFile))
        let outcome = await sender.send(.url(URL(string: "https://example.com/path?q=one")!))
        guard case .success(let receipt) = outcome else { return XCTFail("Expected a confirmed share") }
        XCTAssertEqual(receipt.kind, .url)
        XCTAssertEqual(URL(fileURLWithPath: receipt.fileName).pathExtension, "url")
        XCTAssertEqual(provider.capturedContents, ["[InternetShortcut]\nURL=https://example.com/path?q=one\n"])
    }

    func testURLCanBeSentAsPlainText() async {
        let provider = FakeClipboardSharingProvider()
        let sender = makeSender(provider: provider, preferences: .init(urlSendFormat: .plainText))
        let outcome = await sender.send(.url(URL(string: "https://example.com/")!))
        guard case .success(let receipt) = outcome else { return XCTFail("Expected a confirmed share") }
        XCTAssertEqual(receipt.kind, .url)
        XCTAssertEqual(URL(fileURLWithPath: receipt.fileName).pathExtension, "txt")
        XCTAssertEqual(provider.capturedContents, ["https://example.com/"])
    }

    func testSendWaitsForDelegateResultAndDeletesFileAfterCallback() async throws {
        let provider = FakeClipboardSharingProvider(completesImmediately: false)
        let directory = temporaryDirectory()
        let sender = makeSender(provider: provider, directory: directory)
        let sendTask = Task { await sender.send(.text("send this exact text")) }

        while provider.pendingCompletion == nil { await Task.yield() }
        let fileURL = try XCTUnwrap(provider.performedURLs.first)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), "send this exact text")

        provider.complete(.shared)
        let outcome = await sendTask.value
        guard case .success = outcome else { return XCTFail("Expected the delegate success callback") }
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func testTemporaryFilesAreRemovedAfterFailureCancellationAndUnavailableService() async {
        let results: [(ClipboardSharingResult, ClipboardSendOutcome)] = [
            (.failed("Share failed"), .failure(.sharingFailed("Share failed"))),
            (.cancelled, .cancelled),
            (.unavailable, .failure(.airDropUnavailable))
        ]

        for (shareResult, expectedOutcome) in results {
            let provider = FakeClipboardSharingProvider(result: shareResult)
            let directory = temporaryDirectory()
            let sender = makeSender(provider: provider, directory: directory)
            let outcome = await sender.send(.text("temporary"))
            XCTAssertEqual(outcome, expectedOutcome)
            XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
        }
    }

    func testStartupAndShutdownClearTemporaryDirectory() async throws {
        let directory = temporaryDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let staleFile = directory.appendingPathComponent("stale.txt")
        try "old clipboard".write(to: staleFile, atomically: true, encoding: .utf8)

        let provider = FakeClipboardSharingProvider(completesImmediately: false)
        let sender = makeSender(provider: provider, directory: directory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: staleFile.path))

        let sendTask = Task { await sender.send(.text("active send")) }
        while provider.pendingCompletion == nil { await Task.yield() }
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
        sender.cleanupTemporaryFiles()
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
        provider.complete(.cancelled)
        let outcome = await sendTask.value
        XCTAssertEqual(outcome, .cancelled)
    }

    func testSharingFailureMapsCancellationSeparately() {
        let cancelled = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        let failed = NSError(domain: "AirDrop", code: 1, userInfo: [NSLocalizedDescriptionKey: "AirDrop failed"])
        XCTAssertEqual(AirDropClipboardSharingProvider.result(for: cancelled), .cancelled)
        XCTAssertEqual(AirDropClipboardSharingProvider.result(for: failed), .failed("AirDrop failed"))
    }

    func testRouterSendsCurrentClipboardURLThroughUnifiedInterface() async {
        let defaults = makeDefaults()
        let provider = FakeClipboardSharingProvider()
        let pasteboard = namedPasteboard()
        pasteboard.setString("  https://example.com/path  ", forType: .string)
        let history = ClipboardHistoryStore(pasteboard: pasteboard)
        let reviewRequests = makeReviewCoordinator(defaults: defaults)
        let composition = ClipDropAppComposition(
            defaults: defaults,
            sender: makeSender(provider: provider),
            historyStore: history,
            reviewRequests: reviewRequests
        )

        let outcome = await composition.router.sendCurrentClipboard(source: .popover)
        guard case .success(let receipt) = outcome else { return XCTFail("Expected a confirmed share") }
        XCTAssertEqual(receipt.kind, .url)
        XCTAssertEqual(provider.capturedContents, ["https://example.com/path"])
        XCTAssertEqual(reviewRequests.successfulSendCount, 1)
    }

    func testReviewCountsOnlySuccessfulSendsAndRequestsAtNaturalMoment() async {
        let defaults = makeDefaults()
        var systemRequestCount = 0
        let reviewRequests = makeReviewCoordinator(defaults: defaults) { systemRequestCount += 1 }
        let provider = FakeClipboardSharingProvider()
        let composition = ClipDropAppComposition(
            defaults: defaults,
            sender: makeSender(provider: provider),
            reviewRequests: reviewRequests
        )

        for _ in 0..<3 {
            let outcome = await composition.router.send(.text("sent"), source: .services)
            guard case .success = outcome else { return XCTFail("Expected a confirmed share") }
        }
        XCTAssertEqual(reviewRequests.successfulSendCount, 3)
        XCTAssertEqual(systemRequestCount, 0)
        XCTAssertTrue(reviewRequests.requestIfEligibleAtNaturalMoment())
        XCTAssertEqual(systemRequestCount, 1)
        XCTAssertFalse(reviewRequests.requestIfEligibleAtNaturalMoment())
    }

    func testFailedOrCancelledSendDoesNotQualifyForReview() async {
        let defaults = makeDefaults()
        var systemRequestCount = 0
        let reviewRequests = makeReviewCoordinator(defaults: defaults) { systemRequestCount += 1 }
        let provider = FakeClipboardSharingProvider(result: .cancelled)
        let composition = ClipDropAppComposition(
            defaults: defaults,
            sender: makeSender(provider: provider),
            reviewRequests: reviewRequests
        )

        let outcome = await composition.router.send(.text("cancelled"), source: .popover)
        XCTAssertEqual(outcome, .cancelled)
        XCTAssertEqual(reviewRequests.successfulSendCount, 0)
        XCTAssertFalse(reviewRequests.requestIfEligibleAtNaturalMoment())
        XCTAssertEqual(systemRequestCount, 0)
    }

    func testOnboardingSessionHasTwoStepsAndCompletesOnFinalAction() {
        var finishCount = 0
        let session = ClipDropOnboardingSession { finishCount += 1 }
        XCTAssertEqual(session.phase, .howToSend)

        session.advance()
        XCTAssertEqual(session.phase, .receiverTips)
        session.back()
        XCTAssertEqual(session.phase, .howToSend)
        session.advance()
        session.advance()

        XCTAssertEqual(finishCount, 1)
        session.complete()
        XCTAssertEqual(finishCount, 1)
    }

    func testDefaultHistoryLimitMatchesAppConfig() {
        XCTAssertEqual(ClipDropAppConfig.default.maxRecentItems, 10)
        let store = historyStore()
        for index in 0..<12 {
            store.record("item-\(index)")
        }
        XCTAssertEqual(store.items.count, 10)
    }

    func testVersionSummaryUsesStableFormat() {
        XCTAssertEqual(ClipDropController.versionSummary(version: "1.2.0", build: "4"), "Version 1.2.0 (4)")
    }

    private func makeSender(
        provider: FakeClipboardSharingProvider,
        directory: URL? = nil,
        preferences: ClipDropSendPreferences = .init()
    ) -> ClipboardSenderService {
        ClipboardSenderService(
            sharingProvider: provider,
            temporaryDirectory: directory ?? temporaryDirectory(),
            preferences: { preferences }
        )
    }

    private func makeReviewCoordinator(
        defaults: UserDefaults,
        request: @escaping () -> Void = {}
    ) -> ClipDropReviewRequestCoordinator {
        ClipDropReviewRequestCoordinator(
            defaults: defaults,
            appVersion: "4",
            now: { Date(timeIntervalSince1970: 1_800_000_000) },
            requestSystemReview: request
        )
    }

    private func makeDefaults() -> UserDefaults {
        let name = "ClipDropTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func historyItem(
        _ text: String,
        contentType: ClipboardContentType = .text
    ) -> ClipboardHistoryItem {
        ClipboardHistoryItem(id: UUID(), text: text, contentType: contentType, createdAt: Date())
    }

    private func historyStore(maxItemCount: Int = ClipDropAppConfig.default.maxRecentItems) -> ClipboardHistoryStore {
        ClipboardHistoryStore(pasteboard: namedPasteboard(), maxItemCount: maxItemCount)
    }

    private func namedPasteboard() -> NSPasteboard {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()
        return pasteboard
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipDropTests-\(UUID().uuidString)", isDirectory: true)
    }
}

@MainActor
private final class FakeClipboardSharingProvider: ClipboardSharingProviding {
    private let result: ClipboardSharingResult
    private let completesImmediately: Bool
    private(set) var performedURLs: [URL] = []
    private(set) var capturedContents: [String] = []
    private(set) var pendingCompletion: (@MainActor (ClipboardSharingResult) -> Void)?

    init(result: ClipboardSharingResult = .shared, completesImmediately: Bool = true) {
        self.result = result
        self.completesImmediately = completesImmediately
    }

    func performAirDrop(
        with fileURL: URL,
        completion: @escaping @MainActor (ClipboardSharingResult) -> Void
    ) {
        performedURLs.append(fileURL)
        capturedContents.append((try? String(contentsOf: fileURL, encoding: .utf8)) ?? "")
        if completesImmediately {
            completion(result)
        } else {
            pendingCompletion = completion
        }
    }

    func complete(_ result: ClipboardSharingResult) {
        let completion = pendingCompletion
        pendingCompletion = nil
        completion?(result)
    }
}
