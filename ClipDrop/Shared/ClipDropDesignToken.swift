import SwiftUI

enum ClipDropDesignToken {
    enum Colors {
        static let accentPurple = Color(red: 0.47, green: 0.32, blue: 0.95)
        static let brandColor = accentPurple
        static let textType = Color(red: 0.18, green: 0.45, blue: 0.78)
        static let formattedTextType = Color(red: 0.92, green: 0.38, blue: 0.12)
        static let linkType = Color(red: 0.16, green: 0.58, blue: 0.32)
    }

    enum Opacity {
        static let divider = 0.45
        static let rowAccent = 0.64
        static let windowTint = 0.68
    }

    enum Size {
        static let popoverWidth: CGFloat = 420
        static let popoverHeight: CGFloat = 500
        static let rowMinHeight: CGFloat = 44
    }

    enum Spacing {
        static let page: CGFloat = 14
        static let headerVertical: CGFloat = 11
        static let footerHorizontal: CGFloat = 12
        static let footerVertical: CGFloat = 9
        static let sectionTop: CGFloat = 11
    }
}
