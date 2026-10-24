import AppKit
import Foundation

enum ClipboardSenderError: LocalizedError, Equatable {
    case emptyClipboard
    case airDropUnavailable
    case sharingFailed(String)
    case temporaryFileFailed(String)
    case sendAlreadyInProgress

    var errorDescription: String? {
        switch self {
        case .emptyClipboard:
            return "The clipboard does not contain text or a link."
        case .airDropUnavailable:
            return "AirDrop is not available on this Mac right now."
        case .sharingFailed(let message):
            return message
        case .temporaryFileFailed(let message):
            return "Couldn’t create the temporary file: \(message)"
        case .sendAlreadyInProgress:
            return "A send is already in progress."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyClipboard:
            return "Copy a URL, command, code, address, or any text before sending."
        case .airDropUnavailable:
            return "Check Finder AirDrop settings and try again."
        case .sharingFailed, .temporaryFileFailed:
            return "Try sending again."
        case .sendAlreadyInProgress:
            return nil
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
        with fileURL: URL,
        completion: @escaping @MainActor (ClipboardSharingResult) -> Void
    )
}

@MainActor
final class AirDropClipboardSharingProvider: NSObject, ClipboardSharingProviding, NSSharingServiceDelegate {
    private struct PendingShare {
        let service: NSSharingService
        let completion: @MainActor (ClipboardSharingResult) -> Void
    }

    private var pendingShares: [ObjectIdentifier: PendingShare] = [:]

    func performAirDrop(
        with fileURL: URL,
        completion: @escaping @MainActor (ClipboardSharingResult) -> Void
    ) {
        guard let service = NSSharingService(named: .sendViaAirDrop) else {
            completion(.unavailable)
            return
        }

        let identifier = ObjectIdentifier(service)
        pendingShares[identifier] = PendingShare(service: service, completion: completion)
        service.delegate = self
        service.perform(withItems: [fileURL])
    }

    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) {
        finish(sharingService, result: .shared)
    }

    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        finish(sharingService, result: Self.result(for: error))
    }

    static func result(for error: Error) -> ClipboardSharingResult {
        let cocoaError = error as NSError
        if cocoaError.domain == NSCocoaErrorDomain && cocoaError.code == NSUserCancelledError {
            return .cancelled
        }
        return .failed(error.localizedDescription)
    }

    private func finish(_ service: NSSharingService, result: ClipboardSharingResult) {
        guard let pendingShare = pendingShares.removeValue(forKey: ObjectIdentifier(service)) else {
            return
        }
        pendingShare.completion(result)
    }
}

enum ClipboardSendKind: Equatable {
    case text
    case url
}

struct ClipboardSendReceipt: Equatable {
    let kind: ClipboardSendKind
    let fileName: String
}

enum ClipboardSendOutcome: Equatable {
    case success(ClipboardSendReceipt)
    case failure(ClipboardSenderError)
    case cancelled
}

@MainActor
final class ClipboardSenderService {
    private let fileManager: FileManager
    private let sharingProvider: any ClipboardSharingProviding
    private let temporaryDirectory: URL
    private let now: () -> Date
    private let preferences: () -> ClipDropSendPreferences

    init(
        fileManager: FileManager = .default,
        sharingProvider: (any ClipboardSharingProviding)? = nil,
        temporaryDirectory: URL? = nil,
        now: @escaping () -> Date = Date.init,
        preferences: @escaping () -> ClipDropSendPreferences = { .current }
    ) {
        self.fileManager = fileManager
        self.sharingProvider = sharingProvider ?? AirDropClipboardSharingProvider()
        self.temporaryDirectory = temporaryDirectory ?? fileManager.temporaryDirectory
            .appendingPathComponent("ClipboardDrop", isDirectory: true)
        self.now = now
        self.preferences = preferences
        cleanupTemporaryFiles()
    }

    func send(_ payload: ClipDropPayload) async -> ClipboardSendOutcome {
        let temporaryFile: ClipboardTemporaryFile
        do {
            temporaryFile = try writeTemporaryFile(for: payload)
        } catch let error as ClipboardSenderError {
            return .failure(error)
        } catch {
            return .failure(.temporaryFileFailed(error.localizedDescription))
        }

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<ClipboardSharingResult, Never>) in
            sharingProvider.performAirDrop(with: temporaryFile.url) { result in
                continuation.resume(returning: result)
            }
        }
        defer { removeTemporaryFile(at: temporaryFile.url) }

        switch result {
        case .shared:
            return .success(ClipboardSendReceipt(kind: temporaryFile.kind, fileName: temporaryFile.url.lastPathComponent))
        case .cancelled:
            return .cancelled
        case .failed(let message):
            return .failure(.sharingFailed(message))
        case .unavailable:
            return .failure(.airDropUnavailable)
        }
    }

    func cleanupTemporaryFiles() {
        try? fileManager.removeItem(at: temporaryDirectory)
    }

    private func writeTemporaryFile(for payload: ClipDropPayload) throws -> ClipboardTemporaryFile {
        let kind: ClipboardSendKind
        let fileExtension: String
        let fileText: String
        let sendPreferences = preferences()

        switch payload {
        case .text(let text):
            guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                throw ClipboardSenderError.emptyClipboard
            }
            kind = .text
            fileExtension = sendPreferences.textFileFormat.fileExtension
            fileText = text
        case .url(let url):
            kind = .url
            fileExtension = sendPreferences.urlSendFormat.fileExtension
            fileText = Self.urlFileText(for: url, format: sendPreferences.urlSendFormat)
        }

        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        let fileName = "Clipboard-\(Self.timestamp(for: now()))-\(UUID().uuidString)"
        let fileURL = temporaryDirectory.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        do {
            try fileText.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            removeTemporaryFile(at: fileURL)
            throw error
        }
        return ClipboardTemporaryFile(kind: kind, url: fileURL)
    }

    private func removeTemporaryFile(at url: URL) {
        try? fileManager.removeItem(at: url)
        if let remaining = try? fileManager.contentsOfDirectory(atPath: temporaryDirectory.path), remaining.isEmpty {
            try? fileManager.removeItem(at: temporaryDirectory)
        }
    }

    private static func urlFileText(for url: URL, format: ClipDropURLSendFormat) -> String {
        switch format {
        case .urlFile:
            return "[InternetShortcut]\nURL=\(url.absoluteString)\n"
        case .plainText:
            return url.absoluteString
        }
    }

    private static func timestamp(for date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        return formatter.string(from: date).replacingOccurrences(of: ":", with: "-")
    }
}

private struct ClipboardTemporaryFile {
    let kind: ClipboardSendKind
    let url: URL
}
