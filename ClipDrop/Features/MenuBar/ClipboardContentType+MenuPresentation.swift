import SwiftUI

extension ClipboardContentType {
    var systemImageName: String {
        switch self {
        case .text:
            return "doc.text"
        case .formattedText:
            return "textformat"
        case .link:
            return "link"
        }
    }

    var tint: Color {
        switch self {
        case .text:
            return ClipDropDesignToken.Colors.textType
        case .formattedText:
            return ClipDropDesignToken.Colors.formattedTextType
        case .link:
            return ClipDropDesignToken.Colors.linkType
        }
    }
}
