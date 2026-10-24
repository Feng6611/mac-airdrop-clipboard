import Foundation

enum ClipDropPreferenceKeys {
    static let textFileFormat = "ClipDrop.textFileFormat"
    static let urlSendFormat = "ClipDrop.urlSendFormat"
    static let keepsFormatting = "ClipDrop.keepsFormatting"
    static let editBeforeSending = "ClipDrop.editBeforeSending"
}

enum ClipDropTextFileFormat: String, CaseIterable, Identifiable {
    case plainText = "txt"
    case markdown = "markdown"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plainText:
            return "Plain Text"
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
    case direct = "direct"
    case urlFile = "url"
    case plainText = "txt"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .direct:
            return "Link"
        case .urlFile:
            return "URL File"
        case .plainText:
            return "Text File"
        }
    }

    var fileExtension: String? {
        switch self {
        case .direct:
            return nil
        case .urlFile:
            return "url"
        case .plainText:
            return "txt"
        }
    }
}

struct ClipDropSendPreferences: Equatable {
    static let defaultTextFileFormat: ClipDropTextFileFormat = .plainText
    static let defaultURLSendFormat: ClipDropURLSendFormat = .direct
    static let defaultKeepsFormatting = true
    static let defaultEditBeforeSending = false

    let textFileFormat: ClipDropTextFileFormat
    let urlSendFormat: ClipDropURLSendFormat
    let keepsFormatting: Bool
    let editBeforeSending: Bool

    static var current: ClipDropSendPreferences {
        ClipDropSendPreferences(userDefaults: .standard)
    }

    init(
        textFileFormat: ClipDropTextFileFormat = Self.defaultTextFileFormat,
        urlSendFormat: ClipDropURLSendFormat = Self.defaultURLSendFormat,
        keepsFormatting: Bool = Self.defaultKeepsFormatting,
        editBeforeSending: Bool = Self.defaultEditBeforeSending
    ) {
        self.textFileFormat = textFileFormat
        self.urlSendFormat = urlSendFormat
        self.keepsFormatting = keepsFormatting
        self.editBeforeSending = editBeforeSending
    }

    init(userDefaults: UserDefaults) {
        let textFormatRaw = userDefaults.string(forKey: ClipDropPreferenceKeys.textFileFormat)
        let urlFormatRaw = userDefaults.string(forKey: ClipDropPreferenceKeys.urlSendFormat)

        self.textFileFormat = textFormatRaw.flatMap(ClipDropTextFileFormat.init(rawValue:)) ?? Self.defaultTextFileFormat
        self.urlSendFormat = urlFormatRaw.flatMap(ClipDropURLSendFormat.init(rawValue:)) ?? Self.defaultURLSendFormat
        self.keepsFormatting = userDefaults.object(forKey: ClipDropPreferenceKeys.keepsFormatting) as? Bool
            ?? Self.defaultKeepsFormatting
        self.editBeforeSending = userDefaults.object(forKey: ClipDropPreferenceKeys.editBeforeSending) as? Bool
            ?? Self.defaultEditBeforeSending
    }
}
