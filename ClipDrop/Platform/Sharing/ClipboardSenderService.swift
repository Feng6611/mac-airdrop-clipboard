import AppKit
import Foundation

enum ClipboardSenderError: LocalizedError, Equatable {
    case emptyClipboard
    case airDropUnavailable
    case sharingFailed(String)
    case temporaryFileFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyClipboard:
            return "The clipboard does not contain sendable content."
        case .airDropUnavailable:
            return "AirDrop is not available on this Mac right now."
        case .sharingFailed(let message):
            return message
        case .temporaryFileFailed(let message):
            return "Couldn’t create the temporary file: \(message)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyClipboard:
            return "Copy text, a link, an image, or files before sending."
        case .airDropUnavailable:
            return "Check Finder AirDrop settings and try again."
        case .sharingFailed, .temporaryFileFailed:
            return "Try sending again."
        }
    }
}

enum ClipboardSharingResult: Equatable {
    case shared
    case cancelled
    case failed(String)
    case unavailable
}

@MainActor
protocol ClipboardSharingProviding: AnyObject {
    func performAirDrop(
        withItems items: [Any],
        completion: @escaping @MainActor (ClipboardSharingResult) -> Void
    )
}

@MainActor
final class AirDropClipboardSharingProvider: NSObject, ClipboardSharingProviding, NSSharingServiceDelegate {
    private struct PendingShare {
        let service: NSSharingService
        let urls: [URL]
        let completion: @MainActor (ClipboardSharingResult) -> Void

        func matches(_ callbackItems: [Any]) -> Bool {
            let callbackURLs = callbackItems.compactMap { $0 as? URL }
            return !urls.isEmpty && urls == callbackURLs
        }
    }

    private var pendingShares: [ObjectIdentifier: [PendingShare]] = [:]

    func performAirDrop(
        withItems items: [Any],
        completion: @escaping @MainActor (ClipboardSharingResult) -> Void
    ) {
        guard let service = NSSharingService(named: .sendViaAirDrop) else {
            completion(.unavailable)
            return
        }

        let identifier = ObjectIdentifier(service)
        let pendingShare = PendingShare(
            service: service,
            urls: items.compactMap { $0 as? URL },
            completion: completion
        )
        pendingShares[identifier, default: []].append(pendingShare)
        service.delegate = self
        service.perform(withItems: items)
    }

    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        finish(sharingService, items: items, result: .shared)
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        finish(sharingService, items: items, result: Self.result(for: error))
    }

    static func result(for error: Error) -> ClipboardSharingResult {
        let cocoaError = error as NSError
        if cocoaError.domain == NSCocoaErrorDomain && cocoaError.code == NSUserCancelledError {
            return .cancelled
        }
        return .failed(error.localizedDescription)
    }

    private func finish(_ service: NSSharingService, items: [Any], result: ClipboardSharingResult) {
        let identifier = ObjectIdentifier(service)
        guard var serviceShares = pendingShares[identifier], !serviceShares.isEmpty else {
            return
        }

        let matchingIndex = serviceShares.firstIndex { $0.matches(items) } ?? serviceShares.startIndex
        let pendingShare = serviceShares.remove(at: matchingIndex)
        if serviceShares.isEmpty {
            pendingShares.removeValue(forKey: identifier)
        } else {
            pendingShares[identifier] = serviceShares
        }
        pendingShare.completion(result)
    }
}

enum ClipboardSendKind: Equatable {
    case text
    case url
    case richText
    case image
    case files
}

struct ClipboardSendReceipt: Equatable {
    let kind: ClipboardSendKind
    let fileName: String
    let usedFilenameFallback: Bool
}

enum ClipboardSendOutcome: Equatable {
    case success(ClipboardSendReceipt)
    case failure(ClipboardSenderError)
    case cancelled
}

@MainActor
final class ClipboardSenderService {
    private struct PreparedShare {
        let items: [Any]
        let kind: ClipboardSendKind
        let receiptName: String
        let temporaryFileURL: URL?
        let scopedURLs: [URL]
        let usedFilenameFallback: Bool
    }

    private struct RetainedResource {
        let temporaryFileURL: URL?
        let scopedURLs: [URL]
    }

    private let fileManager: FileManager
    private let sharingProvider: any ClipboardSharingProviding
    private let temporaryDirectory: URL
    private let now: () -> Date
    private let preferences: () -> ClipDropSendPreferences
    private let successfulFileRetentionInterval: TimeInterval
    private let fileAccessChecker: ((URL) -> Bool)?
    private var retainedResources: [UUID: RetainedResource] = [:]
    private var retainedCleanupTasks: [UUID: Task<Void, Never>] = [:]

    init(
        fileManager: FileManager = .default,
        sharingProvider: (any ClipboardSharingProviding)? = nil,
        temporaryDirectory: URL? = nil,
        now: @escaping () -> Date = Date.init,
        preferences: @escaping () -> ClipDropSendPreferences = { .current },
        successfulFileRetentionInterval: TimeInterval = 10 * 60,
        fileAccessChecker: ((URL) -> Bool)? = nil
    ) {
        self.fileManager = fileManager
        self.sharingProvider = sharingProvider ?? AirDropClipboardSharingProvider()
        self.temporaryDirectory = temporaryDirectory ?? fileManager.temporaryDirectory
            .appendingPathComponent("ClipboardDrop", isDirectory: true)
        self.now = now
        self.preferences = preferences
        self.successfulFileRetentionInterval = successfulFileRetentionInterval
        self.fileAccessChecker = fileAccessChecker
        cleanupTemporaryFiles()
    }

    func send(_ payload: ClipDropPayload) async -> ClipboardSendOutcome {
        let preparedShare: PreparedShare
        do {
            preparedShare = try prepareShare(for: payload)
        } catch let error as ClipboardSenderError {
            return .failure(error)
        } catch {
            return .failure(.temporaryFileFailed(error.localizedDescription))
        }

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<ClipboardSharingResult, Never>) in
            sharingProvider.performAirDrop(withItems: preparedShare.items) { result in
                continuation.resume(returning: result)
            }
        }

        switch result {
        case .shared:
            retain(preparedShare)
            return .success(ClipboardSendReceipt(
                kind: preparedShare.kind,
                fileName: preparedShare.receiptName,
                usedFilenameFallback: preparedShare.usedFilenameFallback
            ))
        case .cancelled:
            release(preparedShare)
            return .cancelled
        case .failed(let message):
            release(preparedShare)
            return .failure(.sharingFailed(message))
        case .unavailable:
            release(preparedShare)
            return .failure(.airDropUnavailable)
        }
    }

    func cleanupTemporaryFiles() {
        for task in retainedCleanupTasks.values {
            task.cancel()
        }
        retainedCleanupTasks.removeAll()
        for resource in retainedResources.values {
            release(resource)
        }
        retainedResources.removeAll()
        try? fileManager.removeItem(at: temporaryDirectory)
    }

    private func prepareShare(for payload: ClipDropPayload) throws -> PreparedShare {
        let sendPreferences = preferences()

        switch payload {
        case .text(let text):
            return try writeTextFile(text, kind: .text, format: sendPreferences.textFileFormat)
        case .url(let url):
            guard url.scheme?.lowercased() == "http" || url.scheme?.lowercased() == "https" else {
                return try writeTextFile(url.absoluteString, kind: .url, format: .plainText)
            }
            switch sendPreferences.urlSendFormat {
            case .direct:
                return PreparedShare(
                    items: [url],
                    kind: .url,
                    receiptName: url.lastPathComponent.isEmpty ? url.absoluteString : url.lastPathComponent,
                    temporaryFileURL: nil,
                    scopedURLs: [],
                    usedFilenameFallback: false
                )
            case .plainText, .urlFile:
                return try writeURLFile(url, format: sendPreferences.urlSendFormat)
            }
        case .richText(let attributedText, let plainText):
            guard !plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw ClipboardSenderError.emptyClipboard
            }
            guard sendPreferences.keepsFormatting else {
                return try writeTextFile(plainText, kind: .text, format: sendPreferences.textFileFormat)
            }
            do {
                let range = NSRange(location: 0, length: attributedText.length)
                let data = try attributedText.data(
                    from: range,
                    documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                )
                return try writeDataFile(data, extension: "rtf", kind: .richText)
            } catch {
                throw ClipboardSenderError.temporaryFileFailed(error.localizedDescription)
            }
        case .image(let pngData):
            guard !pngData.isEmpty else { throw ClipboardSenderError.emptyClipboard }
            return try writeDataFile(pngData, extension: "png", kind: .image)
        case .files(let urls):
            guard !urls.isEmpty else { throw ClipboardSenderError.emptyClipboard }
            guard let scopedURLs = acquireFileAccess(for: urls) else {
                return try writeTextFile(
                    urls.map(\.lastPathComponent).joined(separator: "\n"),
                    kind: .text,
                    format: sendPreferences.textFileFormat,
                    usedFilenameFallback: true
                )
            }
            return PreparedShare(
                items: urls,
                kind: .files,
                receiptName: urls.count == 1 ? urls[0].lastPathComponent : "\(urls.count) files",
                temporaryFileURL: nil,
                scopedURLs: scopedURLs,
                usedFilenameFallback: false
            )
        }
    }

    private func writeTextFile(
        _ text: String,
        kind: ClipboardSendKind,
        format: ClipDropTextFileFormat,
        usedFilenameFallback: Bool = false
    ) throws -> PreparedShare {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ClipboardSenderError.emptyClipboard
        }
        return try writeDataFile(
            Data(text.utf8),
            extension: format.fileExtension,
            kind: kind,
            usedFilenameFallback: usedFilenameFallback
        )
    }

    private func writeURLFile(_ url: URL, format: ClipDropURLSendFormat) throws -> PreparedShare {
        let fileText: String
        let fileExtension: String
        switch format {
        case .direct:
            return PreparedShare(
                items: [url],
                kind: .url,
                receiptName: url.absoluteString,
                temporaryFileURL: nil,
                scopedURLs: [],
                usedFilenameFallback: false
            )
        case .urlFile:
            fileText = "[InternetShortcut]\nURL=\(url.absoluteString)\n"
            fileExtension = "url"
        case .plainText:
            fileText = url.absoluteString
            fileExtension = "txt"
        }
        return try writeDataFile(Data(fileText.utf8), extension: fileExtension, kind: .url)
    }

    private func writeDataFile(
        _ data: Data,
        extension fileExtension: String,
        kind: ClipboardSendKind,
        usedFilenameFallback: Bool = false
    ) throws -> PreparedShare {
        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        let fileName = "Clipboard-\(Self.timestamp(for: now()))-\(UUID().uuidString).\(fileExtension)"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            removeTemporaryFile(at: fileURL)
            throw ClipboardSenderError.temporaryFileFailed(error.localizedDescription)
        }
        return PreparedShare(
            items: [fileURL],
            kind: kind,
            receiptName: fileName,
            temporaryFileURL: fileURL,
            scopedURLs: [],
            usedFilenameFallback: usedFilenameFallback
        )
    }

    private func acquireFileAccess(for urls: [URL]) -> [URL]? {
        var scopedURLs: [URL] = []
        for url in urls {
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            let isAccessible = fileAccessChecker?(url)
                ?? (didStartAccessing || fileManager.isReadableFile(atPath: url.path))
            guard isAccessible else {
                for scopedURL in scopedURLs {
                    scopedURL.stopAccessingSecurityScopedResource()
                }
                return nil
            }
            if didStartAccessing {
                scopedURLs.append(url)
            }
        }
        return scopedURLs
    }

    private func retain(_ preparedShare: PreparedShare) {
        guard preparedShare.temporaryFileURL != nil || !preparedShare.scopedURLs.isEmpty else { return }
        let identifier = UUID()
        retainedResources[identifier] = RetainedResource(
            temporaryFileURL: preparedShare.temporaryFileURL,
            scopedURLs: preparedShare.scopedURLs
        )
        retainedCleanupTasks[identifier] = Task { [weak self] in
            let nanoseconds = UInt64(max(0, self?.successfulFileRetentionInterval ?? 0) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.releaseRetainedResource(identifier)
        }
    }

    private func release(_ preparedShare: PreparedShare) {
        if let temporaryFileURL = preparedShare.temporaryFileURL {
            removeTemporaryFile(at: temporaryFileURL)
        }
        for url in preparedShare.scopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
    }

    private func release(_ resource: RetainedResource) {
        if let temporaryFileURL = resource.temporaryFileURL {
            removeTemporaryFile(at: temporaryFileURL)
        }
        for url in resource.scopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
    }

    private func releaseRetainedResource(_ identifier: UUID) {
        retainedCleanupTasks.removeValue(forKey: identifier)
        guard let resource = retainedResources.removeValue(forKey: identifier) else { return }
        release(resource)
    }

    private func removeTemporaryFile(at url: URL) {
        try? fileManager.removeItem(at: url)
        if let remaining = try? fileManager.contentsOfDirectory(atPath: temporaryDirectory.path), remaining.isEmpty {
            try? fileManager.removeItem(at: temporaryDirectory)
        }
    }

    private static func timestamp(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "-")
    }
}
