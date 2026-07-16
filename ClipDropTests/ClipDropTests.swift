import AppKit
import KikiCommerceCore
import KikiCommerceTesting
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
        XCTAssertEqual(controller.currentClipboardItem?.contentType, .link)
        XCTAssertTrue(controller.hasSendableCurrentClipboard)
    }

    func testControllerClearsHistoryAndCurrentClipboardPresentation() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()
        pasteboard.setString("private note", forType: .string)
        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        let controller = ClipDropController(
            sender: ClipboardSenderService(pasteboard: pasteboard, sharingProvider: FakeClipboardSharingProvider()),
            historyStore: store
        )

        controller.refreshClipboardHistory()
        XCTAssertTrue(controller.hasSendableCurrentClipboard)

        controller.clearClipboardHistory()

        XCTAssertTrue(controller.historyItems.isEmpty)
        XCTAssertNil(controller.currentClipboardItem)
        XCTAssertFalse(controller.hasSendableCurrentClipboard)
        XCTAssertEqual(controller.statusSummary, "History cleared")
    }

    func testCurrentClipboardSendReportsAirDropOpened() throws {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()
        pasteboard.setString("send this exact text", forType: .string)
        let sharingProvider = FakeClipboardSharingProvider()
        let store = ClipboardHistoryStore(pasteboard: pasteboard)
        let controller = ClipDropController(
            sender: ClipboardSenderService(pasteboard: pasteboard, sharingProvider: sharingProvider),
            historyStore: store
        )

        controller.refreshClipboardHistory()
        controller.sendClipboardViaAirDrop()

        XCTAssertEqual(controller.statusSummary, "AirDrop opened")
        XCTAssertEqual(sharingProvider.performedURLs.count, 1)
        XCTAssertEqual(
            try String(contentsOf: XCTUnwrap(sharingProvider.performedURLs.first), encoding: .utf8),
            "send this exact text"
        )
    }

    func testEmptyClipboardDoesNotOpenPaywall() {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()
        let composition = ClipDropAppComposition(
            defaults: makeCommerceDefaults(),
            commerceClient: KikiInMemoryCommerceClient(),
            sender: ClipboardSenderService(
                pasteboard: pasteboard,
                sharingProvider: FakeClipboardSharingProvider()
            ),
            historyStore: ClipboardHistoryStore(pasteboard: pasteboard)
        )

        composition.router.sendClipboardViaAirDrop()

        XCTAssertFalse(composition.settingsRoute.isPaywallSheetPresented)
        XCTAssertEqual(composition.controller.statusSummary, "Nothing to send")
    }

    func testUnresolvedAccessRefreshesBeforeShowingPaywall() async {
        let client = KikiInMemoryCommerceClient()
        let sharingProvider = FakeClipboardSharingProvider()
        let composition = ClipDropAppComposition(
            defaults: makeCommerceDefaults(),
            commerceClient: client,
            sender: ClipboardSenderService(sharingProvider: sharingProvider),
            presentAccessVerificationError: {}
        )
        let item = ClipboardHistoryItem(
            id: UUID(),
            text: "send after access check",
            contentType: .text,
            createdAt: Date()
        )

        composition.router.sendHistoryItemViaAirDrop(item)
        XCTAssertFalse(composition.settingsRoute.isPaywallSheetPresented)

        await Task.yield()
        await composition.router.refreshAccess()

        XCTAssertEqual(client.refreshCallCount, 1)
        XCTAssertTrue(composition.settingsRoute.isPaywallSheetPresented)
        XCTAssertTrue(sharingProvider.performedURLs.isEmpty)
    }

    func testDegradedAccessDoesNotClassifyUserAsUnpaid() async {
        let client = KikiInMemoryCommerceClient()
        client.refreshResult = .failure(.network)
        let sharingProvider = FakeClipboardSharingProvider()
        var verificationErrorCount = 0
        let composition = ClipDropAppComposition(
            defaults: makeCommerceDefaults(),
            commerceClient: client,
            sender: ClipboardSenderService(sharingProvider: sharingProvider),
            presentAccessVerificationError: { verificationErrorCount += 1 }
        )
        let item = ClipboardHistoryItem(
            id: UUID(),
            text: "do not misclassify",
            contentType: .text,
            createdAt: Date()
        )

        composition.router.sendHistoryItemViaAirDrop(item)
        await Task.yield()
        await composition.router.refreshAccess()

        guard case .degraded = composition.accessManager.readiness else {
            return XCTFail("Expected a failed refresh to leave access readiness degraded")
        }
        XCTAssertFalse(composition.settingsRoute.isPaywallSheetPresented)
        XCTAssertTrue(sharingProvider.performedURLs.isEmpty)
        XCTAssertEqual(verificationErrorCount, 1)
    }

    func testCachedProCanSendBeforeInitialRefreshFinishes() {
        let purchaseDate = Date(timeIntervalSince1970: 30_000)
        let entitlement = CommerceEntitlement(
            plan: ClipDropPurchasePlan.lifetime.commercePlan,
            productIdentifier: ClipDropRevenueCatConfiguration.lifetimeProductIdentifier,
            entitlementIdentifier: ClipDropRevenueCatConfiguration.entitlementIdentifier,
            expirationDate: nil,
            originalPurchaseDate: purchaseDate
        )
        let client = KikiInMemoryCommerceClient(entitlement: entitlement)
        let sharingProvider = FakeClipboardSharingProvider()
        let composition = ClipDropAppComposition(
            defaults: makeCommerceDefaults(),
            commerceClient: client,
            sender: ClipboardSenderService(sharingProvider: sharingProvider)
        )
        let item = ClipboardHistoryItem(
            id: UUID(),
            text: "cached pro send",
            contentType: .text,
            createdAt: purchaseDate
        )

        composition.router.sendHistoryItemViaAirDrop(item)

        XCTAssertEqual(client.refreshCallCount, 0)
        XCTAssertFalse(composition.settingsRoute.isPaywallSheetPresented)
        XCTAssertEqual(sharingProvider.performedURLs.count, 1)
    }

    func testQueuedCurrentClipboardSendUsesTheItemChosenBeforeRefresh() async throws {
        let purchaseDate = Date(timeIntervalSince1970: 40_000)
        let entitlement = CommerceEntitlement(
            plan: ClipDropPurchasePlan.lifetime.commercePlan,
            productIdentifier: ClipDropRevenueCatConfiguration.lifetimeProductIdentifier,
            entitlementIdentifier: ClipDropRevenueCatConfiguration.entitlementIdentifier,
            expirationDate: nil,
            originalPurchaseDate: purchaseDate
        )
        let client = KikiInMemoryCommerceClient()
        client.refreshResult = .success(entitlement)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name(UUID().uuidString))
        pasteboard.clearContents()
        pasteboard.setString("chosen before refresh", forType: .string)
        let sharingProvider = FakeClipboardSharingProvider()
        let composition = ClipDropAppComposition(
            defaults: makeCommerceDefaults(),
            commerceClient: client,
            sender: ClipboardSenderService(pasteboard: pasteboard, sharingProvider: sharingProvider),
            historyStore: ClipboardHistoryStore(pasteboard: pasteboard)
        )

        composition.router.sendClipboardViaAirDrop()
        pasteboard.clearContents()
        pasteboard.setString("copied while refreshing", forType: .string)
        await Task.yield()
        await composition.router.refreshAccess()

        let sentURL = try XCTUnwrap(sharingProvider.performedURLs.first)
        XCTAssertEqual(
            try String(contentsOf: sentURL, encoding: .utf8),
            "chosen before refresh"
        )
    }

    func testClearHistoryCancelsQueuedSend() async {
        let purchaseDate = Date(timeIntervalSince1970: 50_000)
        let entitlement = CommerceEntitlement(
            plan: ClipDropPurchasePlan.lifetime.commercePlan,
            productIdentifier: ClipDropRevenueCatConfiguration.lifetimeProductIdentifier,
            entitlementIdentifier: ClipDropRevenueCatConfiguration.entitlementIdentifier,
            expirationDate: nil,
            originalPurchaseDate: purchaseDate
        )
        let client = KikiInMemoryCommerceClient()
        client.refreshResult = .success(entitlement)
        let sharingProvider = FakeClipboardSharingProvider()
        let composition = ClipDropAppComposition(
            defaults: makeCommerceDefaults(),
            commerceClient: client,
            sender: ClipboardSenderService(sharingProvider: sharingProvider)
        )
        let item = ClipboardHistoryItem(
            id: UUID(),
            text: "cancel this send",
            contentType: .text,
            createdAt: purchaseDate
        )

        composition.router.sendHistoryItemViaAirDrop(item)
        composition.router.clearClipboardHistory()
        await Task.yield()
        await composition.router.refreshAccess()

        XCTAssertTrue(sharingProvider.performedURLs.isEmpty)
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

    func testPurchasePlansKeepLifetimePricingAndProductIdentifiersStable() {
        XCTAssertEqual(ClipDropPurchasePlan.allCases.map(\.id), ["lifetime", "supporterLifetime"])
        XCTAssertEqual(ClipDropPurchasePlan.lifetime.fallbackDisplayPrice, "$6.99")
        XCTAssertEqual(ClipDropPurchasePlan.supporterLifetime.fallbackDisplayPrice, "$10.99")
        XCTAssertEqual(ClipDropPurchasePlan.supporterLifetime.title, "Lifetime + Support")
        XCTAssertEqual(
            ClipDropPurchasePlan.supporterLifetime.subtitle,
            "Same Pro features, with extra support for development"
        )
        XCTAssertEqual(
            ClipDropPurchasePlan.allCases.map { $0.commercePlan.rawValue },
            ["lifetime", "supporterLifetime"]
        )
        XCTAssertEqual(ClipDropRevenueCatConfiguration.entitlementIdentifier, "pro")
        XCTAssertEqual(ClipDropRevenueCatConfiguration.offeringIdentifier, "default")
        XCTAssertEqual(
            ClipDropRevenueCatConfiguration.commerceConfiguration.productIdentifiers,
            [
                CommercePlan("lifetime"): "dev.kkuk.clipboarddrop.pro.lifetime",
                CommercePlan("supporterLifetime"): "dev.kkuk.clipboarddrop.pro.supporter"
            ]
        )
    }

    func testExplicitTrialStartsOnlyWhenUserChoosesItAndExpiresAfterTwoDays() async {
        let start = Date(timeIntervalSince1970: 10_000)
        let defaults = makeCommerceDefaults()
        let client = KikiInMemoryCommerceClient()
        let manager = KikiAccessManager(
            configuration: ClipDropRevenueCatConfiguration.accessConfiguration,
            defaults: defaults,
            commerceClient: client,
            now: { start }
        )

        XCTAssertEqual(manager.status, .notStarted)

        await manager.startTrial()

        guard case .trial(.time(let daysRemaining, let expiresAt)) = manager.status else {
            return XCTFail("Expected the explicit trial to become active")
        }
        XCTAssertEqual(daysRemaining, 2)
        XCTAssertEqual(expiresAt, start.addingTimeInterval(ClipDropRevenueCatConfiguration.trialDuration))

        let expiredManager = KikiAccessManager(
            configuration: ClipDropRevenueCatConfiguration.accessConfiguration,
            defaults: defaults,
            commerceClient: client,
            now: { start.addingTimeInterval(ClipDropRevenueCatConfiguration.trialDuration + 1) }
        )
        XCTAssertEqual(expiredManager.status, .expired)
    }

    func testEitherLifetimePurchaseUnlocksTheSameProEntitlement() async throws {
        for plan in ClipDropPurchasePlan.allCases {
            let purchaseDate = Date(timeIntervalSince1970: 20_000)
            let entitlement = CommerceEntitlement(
                plan: plan.commercePlan,
                productIdentifier: plan == .lifetime
                    ? ClipDropRevenueCatConfiguration.lifetimeProductIdentifier
                    : ClipDropRevenueCatConfiguration.supporterProductIdentifier,
                entitlementIdentifier: ClipDropRevenueCatConfiguration.entitlementIdentifier,
                expirationDate: nil,
                originalPurchaseDate: purchaseDate
            )
            let client = KikiInMemoryCommerceClient()
            client.purchaseResults[plan.commercePlan] = .success(entitlement)
            let manager = KikiAccessManager(
                configuration: ClipDropRevenueCatConfiguration.accessConfiguration,
                defaults: makeCommerceDefaults(),
                commerceClient: client,
                now: { purchaseDate }
            )

            try await manager.purchase(planID: plan.id)

            guard case .pro(let unlockedPlan, let snapshot) = manager.status else {
                return XCTFail("Expected \(plan.id) to unlock Pro")
            }
            XCTAssertEqual(unlockedPlan.id, plan.id)
            XCTAssertEqual(snapshot.entitlementIdentifier, "pro")
            XCTAssertEqual(snapshot.originalPurchaseDate, purchaseDate)
        }
    }

    func testMissingOfferingKeepsBothFallbackPlansAvailable() async {
        let manager = KikiAccessManager(
            configuration: ClipDropRevenueCatConfiguration.accessConfiguration,
            defaults: makeCommerceDefaults(),
            commerceClient: KikiInMemoryCommerceClient()
        )

        await manager.loadOfferings()

        XCTAssertEqual(manager.availablePlans.map(\.id), ["lifetime", "supporterLifetime"])
        XCTAssertEqual(manager.availablePlans.map(\.displayPrice), ["$6.99", "$10.99"])
        XCTAssertFalse(manager.availablePlans.contains(where: \.isAvailable))
    }

    private func makeCommerceDefaults() -> UserDefaults {
        let suiteName = "ClipDropTests.Commerce.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
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
