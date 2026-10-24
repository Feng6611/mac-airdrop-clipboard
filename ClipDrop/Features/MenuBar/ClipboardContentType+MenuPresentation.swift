extension ClipboardContentType {
    var systemImageName: String {
        switch self {
        case .text:
            return "doc.text"
        case .formattedText:
            return "textformat"
        case .link:
            return "link"
        case .image:
            return "photo"
        case .files:
            return "doc.on.doc"
        }
    }

}
