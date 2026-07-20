import AppKit
import SwiftUI

/// Design tokens for the menu bar popover.
/// Source of truth for the visual contract: `Docs/DesignSpec-MenuBar.md`.
enum ClipDropDesignToken {
    enum Colors {
        /// Brand purple. Adapts across light/dark so it keeps contrast on a dark popover.
        /// Only used for the app identity mark and Pro CTAs — never inside the list.
        static let brand = Color(nsColor: brandNSColor)

        /// Stable Pro status accent. Access states use this exact purple in Settings.
        static let proAccent = Color(
            red: 203.0 / 255.0,
            green: 48.0 / 255.0,
            blue: 224.0 / 255.0
        )

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

    enum Spacing {
        static let page: CGFloat = 12
        static let headerVertical: CGFloat = 8
        static let footerVertical: CGFloat = 8
        static let rowVertical: CGFloat = 6
        static let rowHorizontal: CGFloat = 10
    }
}
