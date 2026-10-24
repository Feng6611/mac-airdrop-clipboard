import AppKit
import SwiftUI

/// Design tokens for the menu bar popover.
/// Source of truth for the visual contract: `Docs/DesignSpec-MenuBar.md`.
enum ClipDropDesignToken {
    enum Colors {
        /// Brand purple. Adapts across light/dark so it keeps contrast on a dark popover.
        static let brand = Color(nsColor: brandNSColor)

        /// Neutral, system-grayscale fill for row hover / keyboard selection.
        static let rowHover = Color.primary.opacity(0.06)

        private static let brandNSColor = NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return isDark
                ? NSColor(srgbRed: 0.62, green: 0.51, blue: 0.98, alpha: 1)
                : NSColor(srgbRed: 0.47, green: 0.32, blue: 0.95, alpha: 1)
        }
    }

    enum Size {
        static let popoverWidth: CGFloat = 400
        static let popoverHeight: CGFloat = 336
        static let rowMinHeight: CGFloat = 48
        static let brandMark: CGFloat = 18
        static let leadingIcon: CGFloat = 18
        static let iconButtonHit: CGFloat = 26
    }

    enum Settings {
        static let shortcutFieldWidth: CGFloat = 140
        static let shortcutFieldHeight: CGFloat = 22
        static let segmentedWidth: CGFloat = 220
        static let shortcutFieldCornerRadius: CGFloat = 6
        static let shortcutFieldBorderWidth: CGFloat = 0.5
        static let shortcutRecordingBorderWidth: CGFloat = 1.5
        static let shortcutClearIconSize: CGFloat = 12
        static let shortcutClearHitSize: CGFloat = 22
        static let rowIconWidth: CGFloat = 22
        static let rowLabelSpacing: CGFloat = 8
        static let shortcutErrorSpacing: CGFloat = 2
        static let shortcutTextMinimumScaleFactor: CGFloat = 0.75
    }

    enum Spacing {
        static let page: CGFloat = 12
        static let headerVertical: CGFloat = 8
        static let footerVertical: CGFloat = 8
        static let rowVertical: CGFloat = 6
        static let rowHorizontal: CGFloat = 10
    }
}
