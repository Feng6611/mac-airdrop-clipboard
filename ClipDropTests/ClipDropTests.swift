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

    func testHistoryCapsImageMemoryAndItemCount() {
        let store = historyStore(maxImageByteCount: 4, maxImageCount: 2)
        XCTAssertNil(store.record("Large", contentType: .image, imageData: Data(repeating: 0, count: 5)))
        for byte in 1...3 {
            store.record("Image", contentType: .image, imageData: Data([UInt8(byte)]))
        }
        XCTAssertEqual(store.items.count, 2)
        XCTAssertEqual(store.items.compactMap(\.imageData), [Data([3]), Data([2])])
        XCTAssertEqual(ClipboardHistoryStore.maxImageBytes, 20 * 1024 * 1024)
        XCTAssertEqual(ClipboardHistoryStore.maxImageItemCount, 5)
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

    func testPasteboardClassifiesPNGAndTIFFImages() throws {
        let pngPasteboard = namedPasteboard()
        let pngData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
        pngPasteboard.setData(pngData, forType: .png)
        let pngStore = ClipboardHistoryStore(pasteboard: pngPasteboard)
        pngStore.syncCurrentClipboard()
        XCTAssertEqual(pngStore.currentItem?.contentType, .image)
        XCTAssertEqual(pngStore.currentItem?.imageData, pngData)

        let tiffPasteboard = namedPasteboard()
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 1,
            pixelsHigh: 1,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        let tiffData = bitmap.representation(using: .tiff, properties: [:])!
        tiffPasteboard.setData(tiffData, forType: .tiff)
        let tiffStore = ClipboardHistoryStore(pasteboard: tiffPasteboard)
        tiffStore.syncCurrentClipboard()
        XCTAssertEqual(tiffStore.currentItem?.contentType, .image)
        XCTAssertEqual(tiffStore.currentItem?.imageData?.prefix(8), Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]))
    }

    func testPasteboardClassifiesRichTextLinksAndPlainText() throws {
        let richPasteboard = namedPasteboard()
        let styled = NSMutableAttributedString(string: "styled text")
        styled.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 14), range: NSRange(location: 0, length: 6))
        let rtfData = try styled.data(
            from: NSRange(location: 0, length: styled.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        richPasteboard.setString(styled.string, forType: .string)
        richPasteboard.setData(rtfData, forType: .rtf)
        let richStore = ClipboardHistoryStore(pasteboard: richPasteboard)
        richStore.syncCurrentClipboard()
        XCTAssertEqual(richStore.currentItem?.contentType, .formattedText)
        XCTAssertEqual(richStore.currentItem?.attributedText?.string, styled.string)

        let linkPasteboard = namedPasteboard()
        linkPasteboard.setString("https://example.com/path", forType: .string)
        let linkStore = ClipboardHistoryStore(pasteboard: linkPasteboard)
        linkStore.syncCurrentClipboard()
        XCTAssertEqual(linkStore.currentItem?.contentType, .link)

        let textPasteboard = namedPasteboard()
        textPasteboard.setString("plain text", forType: .string)
        let textStore = ClipboardHistoryStore(pasteboard: textPasteboard)
        textStore.syncCurrentClipboard()
        XCTAssertEqual(textStore.currentItem?.contentType, .text)

        XCTAssertEqual(
            ClipboardContentType.classify(text: "https://example.com", hasFormattedRepresentation: true),
            .formattedText
        )
    }

    func testPasteboardClassifiesFinderFileURLs() throws {
        let sourceFile = try makeFile(name: "copied.txt", contents: "source")
        defer { try? FileManager.default.removeItem(at: sourceFile.deletingLastPathComponent()) }
        let pasteboard = namedPasteboard()
        XCTAssertTrue(pasteboard.writeObjects([sourceFile as NSURL]))

        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        store.syncCurrentClipboard()
        XCTAssertEqual(store.currentItem?.contentType, .files)
        XCTAssertEqual(store.currentItem?.fileURLs, [sourceFile])
        XCTAssertEqual(store.currentItem?.text, "copied.txt")
    }

    func testCopyHistoryItemWritesRichTextImageAndFilesToPasteboard() throws {
        let pasteboard = namedPasteboard()
        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        let rich = NSMutableAttributedString(string: "styled")
        rich.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 14), range: NSRange(location: 0, length: rich.length))
        try store.copy(historyItem("styled", contentType: .formattedText, attributedText: rich))
        XCTAssertEqual(pasteboard.string(forType: .string), "styled")

        let pngData = Data([1, 2, 3])
        try store.copy(historyItem("Image", contentType: .image, imageData: pngData))
        XCTAssertEqual(pasteboard.data(forType: .png), pngData)

        let sourceFile = try makeFile(name: "copied.txt", contents: "source")
        defer { try? FileManager.default.removeItem(at: sourceFile.deletingLastPathComponent()) }
        try store.copy(historyItem("copied.txt", contentType: .files, fileURLs: [sourceFile]))
        XCTAssertEqual(pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], [sourceFile])
    }

    func testMergeUsesChronologicalOrderAndRejectsImagesAndFiles() {
        let old = historyItem("old", createdAt: Date(timeIntervalSince1970: 1))
        let middle = historyItem("middle", contentType: .link, createdAt: Date(timeIntervalSince1970: 2))
        let newest = historyItem("newest", createdAt: Date(timeIntervalSince1970: 3))
        XCTAssertEqual(ClipboardContentType.mergedText(from: [newest, old, middle]), "old\n\nmiddle\n\nnewest")
        XCTAssertNil(ClipboardContentType.mergedText(from: [old, historyItem("Image", contentType: .image, imageData: Data([1]))]))
        XCTAssertNil(ClipboardContentType.mergedText(from: [historyItem("file.txt", contentType: .files, fileURLs: [URL(fileURLWithPath: "/tmp/file.txt")])]))
    }

    func testQRCodeCapacityBoundaryUsesUTF8Bytes() {
        XCTAssertTrue(ClipDropQRCodeGenerator.canEncode(String(repeating: "a", count: 2_331)))
        XCTAssertFalse(ClipDropQRCodeGenerator.canEncode(String(repeating: "a", count: 2_332)))
        XCTAssertFalse(ClipDropQRCodeGenerator.canEncode(String(repeating: "界", count: 778)))
        XCTAssertFalse(ClipDropQRCodeGenerator.canEncode(""))
        XCTAssertNotNil(ClipDropQRCodeGenerator.image(for: "https://example.com"))
        XCTAssertNotNil(ClipDropQRCodeGenerator.image(for: String(repeating: "a", count: 2_331)))
        XCTAssertNil(ClipDropQRCodeGenerator.image(for: String(repeating: "a", count: 2_332)))
    }

    func testDefaultSendPreferences() {
        XCTAssertEqual(ClipDropSendPreferences.defaultTextFileFormat, .plainText)
        XCTAssertEqual(ClipDropSendPreferences.defaultURLSendFormat, .direct)
        XCTAssertTrue(ClipDropSendPreferences.defaultKeepsFormatting)
        XCTAssertFalse(ClipDropSendPreferences.defaultEditBeforeSending)
        XCTAssertEqual(ClipDropSendPreferences(), ClipDropSendPreferences(userDefaults: makeDefaults()))
    }

    func testTextAndMarkdownTemporaryFileContents() async throws {
        for (preferences, expectedExtension) in [
            (ClipDropSendPreferences(textFileFormat: .plainText), "txt"),
            (ClipDropSendPreferences(textFileFormat: .markdown), "md")
        ] {
            let provider = FakeClipboardSharingProvider()
            let sender = makeSender(provider: provider, preferences: preferences)
            let outcome = await sender.send(.text("# Notes"))
            guard case .success(let receipt) = outcome else { return XCTFail("Expected a confirmed share") }
            XCTAssertEqual(URL(fileURLWithPath: receipt.fileName).pathExtension, expectedExtension)
            XCTAssertEqual(provider.capturedContents, ["# Notes"])
            sender.cleanupTemporaryFiles()
        }
    }

    func testLinkIsSentDirectlyByDefaultAndSupportsURLAndTextFileFallbacks() async {
        let url = URL(string: "https://example.com/path?q=one")!
        let directProvider = FakeClipboardSharingProvider()
        let directSender = makeSender(provider: directProvider)
        let directOutcome = await directSender.send(.url(url))
        guard case .success(let directReceipt) = directOutcome else { return XCTFail("Expected a confirmed share") }
        XCTAssertEqual(directReceipt.kind, .url)
        XCTAssertEqual(directProvider.performedItems.first?.first as? URL, url)
        XCTAssertFalse(directProvider.performedURLs.first?.isFileURL ?? true)

        for (format, suffix, expectedContent) in [
            (ClipDropURLSendFormat.urlFile, "url", "[InternetShortcut]\nURL=https://example.com/path?q=one\n"),
            (.plainText, "txt", "https://example.com/path?q=one")
        ] {
            let provider = FakeClipboardSharingProvider()
            let sender = makeSender(provider: provider, preferences: .init(urlSendFormat: format))
            let outcome = await sender.send(.url(url))
            guard case .success(let receipt) = outcome else { return XCTFail("Expected a confirmed share") }
            XCTAssertEqual(URL(fileURLWithPath: receipt.fileName).pathExtension, suffix)
            XCTAssertEqual(provider.capturedContents, [expectedContent])
            sender.cleanupTemporaryFiles()
        }
    }

    func testRichTextTemporaryRTFContentAndPlainTextFallback() async throws {
        let attributed = NSMutableAttributedString(string: "formatted")
        attributed.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 14), range: NSRange(location: 0, length: attributed.length))
        let provider = FakeClipboardSharingProvider()
        let sender = makeSender(provider: provider)
        let outcome = await sender.send(.richText(attributed, plain: "formatted"))
        guard case .success(let receipt) = outcome else { return XCTFail("Expected a confirmed share") }
        XCTAssertEqual(receipt.kind, .richText)
        XCTAssertEqual(URL(fileURLWithPath: receipt.fileName).pathExtension, "rtf")
        let rtfData = try Data(contentsOf: try XCTUnwrap(provider.performedURLs.first))
        XCTAssertEqual(NSAttributedString(rtf: rtfData, documentAttributes: nil)?.string, "formatted")
        sender.cleanupTemporaryFiles()

        let plainProvider = FakeClipboardSharingProvider()
        let plainSender = makeSender(
            provider: plainProvider,
            preferences: .init(textFileFormat: .markdown, keepsFormatting: false)
        )
        let plainOutcome = await plainSender.send(.richText(attributed, plain: "formatted"))
        guard case .success(let plainReceipt) = plainOutcome else { return XCTFail("Expected a confirmed share") }
        XCTAssertEqual(plainReceipt.kind, .text)
        XCTAssertEqual(URL(fileURLWithPath: plainReceipt.fileName).pathExtension, "md")
        XCTAssertEqual(plainProvider.capturedContents, ["formatted"])
        plainSender.cleanupTemporaryFiles()
    }

    func testImageIsSentAsPNGTemporaryFile() async throws {
        let pngData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3])
        let provider = FakeClipboardSharingProvider()
        let sender = makeSender(provider: provider)
        let outcome = await sender.send(.image(pngData))
        guard case .success(let receipt) = outcome else { return XCTFail("Expected a confirmed share") }
        XCTAssertEqual(receipt.kind, .image)
        XCTAssertEqual(URL(fileURLWithPath: receipt.fileName).pathExtension, "png")
        XCTAssertEqual(try Data(contentsOf: try XCTUnwrap(provider.performedURLs.first)), pngData)
        sender.cleanupTemporaryFiles()
    }

    func testFilesArePassedDirectlyAndInaccessibleFilesFallBackToNames() async throws {
        let sourceFile = try makeFile(name: "source.txt", contents: "source")
        defer { try? FileManager.default.removeItem(at: sourceFile.deletingLastPathComponent()) }
        let provider = FakeClipboardSharingProvider()
        let sender = makeSender(provider: provider)
        let outcome = await sender.send(.files([sourceFile]))
        guard case .success(let receipt) = outcome else { return XCTFail("Expected a confirmed share") }
        XCTAssertEqual(receipt.kind, .files)
        XCTAssertEqual(provider.performedItems.first?.first as? URL, sourceFile)

        let fallbackProvider = FakeClipboardSharingProvider()
        let fallbackSender = ClipboardSenderService(
            sharingProvider: fallbackProvider,
            temporaryDirectory: temporaryDirectory(),
            fileAccessChecker: { _ in false }
        )
        let fallbackOutcome = await fallbackSender.send(.files([sourceFile]))
        guard case .success(let fallbackReceipt) = fallbackOutcome else { return XCTFail("Expected a confirmed filename fallback") }
        XCTAssertEqual(fallbackReceipt.kind, .text)
        XCTAssertTrue(fallbackReceipt.usedFilenameFallback)
        XCTAssertEqual(fallbackProvider.capturedContents, ["source.txt"])

        let fallbackController = ClipDropController(sender: fallbackSender, historyStore: historyStore())
        _ = await fallbackController.send(.files([sourceFile]))
        XCTAssertEqual(
            fallbackController.sendNotice,
            "AirDrop sent file names because the app couldn’t access the files."
        )
        sender.cleanupTemporaryFiles()
        fallbackSender.cleanupTemporaryFiles()
    }

    func testSuccessfulTemporaryFileSurvivesCallbackThenExpires() async throws {
        let provider = FakeClipboardSharingProvider()
        let directory = temporaryDirectory()
        let sender = makeSender(provider: provider, directory: directory, retention: 0.05)
        let outcome = await sender.send(.text("send this exact text"))
        guard case .success = outcome else { return XCTFail("Expected the delegate success callback") }
        let fileURL = try XCTUnwrap(provider.performedURLs.first)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(try String(contentsOf: fileURL, encoding: .utf8), "send this exact text")

        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func testTemporaryFilesAreRemovedImmediatelyAfterFailureCancellationAndUnavailableService() async {
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

        let sender = makeSender(provider: FakeClipboardSharingProvider(), directory: directory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: staleFile.path))
        let outcome = await sender.send(.text("active send"))
        guard case .success = outcome else { return XCTFail("Expected a confirmed send") }
        let fileURL = try XCTUnwrap(FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).first)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        sender.cleanupTemporaryFiles()
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }

    func testControllerAllowsConcurrentSendsAndTimesOutOnlyTheIndicator() async {
        let provider = FakeClipboardSharingProvider(completesImmediately: false)
        let sender = makeSender(provider: provider)
        let controller = ClipDropController(sender: sender, historyStore: historyStore(), sendIndicatorTimeout: 0.02)

        let first = Task { await controller.send(.text("first")) }
        while provider.pendingCompletions.count < 1 { await Task.yield() }
        let second = Task { await controller.send(.text("second")) }
        while provider.pendingCompletions.count < 2 { await Task.yield() }
        XCTAssertTrue(controller.isSending)

        try? await Task.sleep(nanoseconds: 60_000_000)
        XCTAssertFalse(controller.isSending)

        let third = Task { await controller.send(.text("third")) }
        while provider.pendingCompletions.count < 3 { await Task.yield() }
        XCTAssertTrue(controller.isSending)

        provider.complete(.shared, at: 0)
        provider.complete(.shared, at: 0)
        provider.complete(.shared, at: 0)
        for result in [await first.value, await second.value, await third.value] {
            guard case .success = result else { return XCTFail("Expected all independently tracked sends to succeed") }
        }
        XCTAssertFalse(controller.isSending)
        sender.cleanupTemporaryFiles()
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
        XCTAssertEqual(provider.performedItems.first?.first as? URL, URL(string: "https://example.com/path"))
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
        let composition = ClipDropAppComposition(
            defaults: defaults,
            sender: makeSender(provider: FakeClipboardSharingProvider(result: .cancelled)),
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
        preferences: ClipDropSendPreferences = .init(),
        retention: TimeInterval = 600
    ) -> ClipboardSenderService {
        ClipboardSenderService(
            sharingProvider: provider,
            temporaryDirectory: directory ?? temporaryDirectory(),
            preferences: { preferences },
            successfulFileRetentionInterval: retention
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
        contentType: ClipboardContentType = .text,
        createdAt: Date = Date(),
        attributedText: NSAttributedString? = nil,
        imageData: Data? = nil,
        fileURLs: [URL] = []
    ) -> ClipboardHistoryItem {
        ClipboardHistoryItem(
            id: UUID(),
            text: text,
            contentType: contentType,
            createdAt: createdAt,
            attributedText: attributedText,
            imageData: imageData,
            fileURLs: fileURLs
        )
    }

    private func historyStore(
        maxItemCount: Int = ClipDropAppConfig.default.maxRecentItems,
        maxImageByteCount: Int = ClipboardHistoryStore.maxImageBytes,
        maxImageCount: Int = ClipboardHistoryStore.maxImageItemCount
    ) -> ClipboardHistoryStore {
        ClipboardHistoryStore(
            pasteboard: namedPasteboard(),
            maxItemCount: maxItemCount,
            maxImageByteCount: maxImageByteCount,
            maxImageCount: maxImageCount
        )
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

    private func makeFile(name: String, contents: String) throws -> URL {
        let directory = temporaryDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

@MainActor
private final class FakeClipboardSharingProvider: ClipboardSharingProviding {
    private let result: ClipboardSharingResult
    private let completesImmediately: Bool
    private(set) var performedItems: [[Any]] = []
    private(set) var capturedContents: [String] = []
    private(set) var pendingCompletions: [@MainActor (ClipboardSharingResult) -> Void] = []

    var performedURLs: [URL] {
        performedItems.flatMap { $0.compactMap { $0 as? URL } }
    }

    init(result: ClipboardSharingResult = .shared, completesImmediately: Bool = true) {
        self.result = result
        self.completesImmediately = completesImmediately
    }

    func performAirDrop(
        withItems items: [Any],
        completion: @escaping @MainActor (ClipboardSharingResult) -> Void
    ) {
        performedItems.append(items)
        capturedContents.append(contentsOf: items.compactMap { item in
            guard let url = item as? URL else { return nil }
            return url.isFileURL
                ? (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                : url.absoluteString
        })
        if completesImmediately {
            completion(result)
        } else {
            pendingCompletions.append(completion)
        }
    }

    func complete(_ result: ClipboardSharingResult, at index: Int) {
        guard pendingCompletions.indices.contains(index) else { return }
        let completion = pendingCompletions.remove(at: index)
        completion(result)
    }
}
