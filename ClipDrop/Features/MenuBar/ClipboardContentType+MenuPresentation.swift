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

}
