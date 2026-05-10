import Foundation

enum ClipDropPreferenceKeys {
    static let textFileFormat = "ClipDrop.textFileFormat"
    static let urlSendFormat = "ClipDrop.urlSendFormat"
}

enum ClipDropTextFileFormat: String, CaseIterable, Identifiable {
    case plainText = "txt"
    case markdown = "markdown"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plainText:
            return "TXT"
        case .markdown:
            return "Markdown"
        }
    }

    var fileExtension: String {
        switch self {
        case .plainText:
            return "txt"
        case .markdown:
            return "md"
        }
    }
}

enum ClipDropURLSendFormat: String, CaseIterable, Identifiable {
    case urlFile = "url"
    case plainText = "txt"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .urlFile:
            return "URL"
        case .plainText:
            return "TXT"
        }
    }

    var fileExtension: String {
        switch self {
        case .urlFile:
            return "url"
        case .plainText:
            return "txt"
        }
    }
}

struct ClipDropSendPreferences: Equatable {
    static let defaultTextFileFormat: ClipDropTextFileFormat = .plainText
    static let defaultURLSendFormat: ClipDropURLSendFormat = .plainText

    let textFileFormat: ClipDropTextFileFormat
    let urlSendFormat: ClipDropURLSendFormat

    static var current: ClipDropSendPreferences {
        ClipDropSendPreferences(userDefaults: .standard)
    }

    init(
        textFileFormat: ClipDropTextFileFormat = Self.defaultTextFileFormat,
        urlSendFormat: ClipDropURLSendFormat = Self.defaultURLSendFormat
    ) {
        self.textFileFormat = textFileFormat
        self.urlSendFormat = urlSendFormat
    }

    init(userDefaults: UserDefaults) {
        let textFormatRaw = userDefaults.string(forKey: ClipDropPreferenceKeys.textFileFormat)
        let urlFormatRaw = userDefaults.string(forKey: ClipDropPreferenceKeys.urlSendFormat)

        self.textFileFormat = textFormatRaw.flatMap(ClipDropTextFileFormat.init(rawValue:)) ?? Self.defaultTextFileFormat
        self.urlSendFormat = urlFormatRaw.flatMap(ClipDropURLSendFormat.init(rawValue:)) ?? Self.defaultURLSendFormat
    }
}
