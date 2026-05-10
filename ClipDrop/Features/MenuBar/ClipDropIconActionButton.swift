import SwiftUI

struct ClipDropIconActionButton: View {
    enum Role {
        case primary
        case secondary
    }

    let systemName: String
    let label: String
    let role: Role
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: role.iconSize, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(role.foregroundStyle)
                .frame(width: role.hitSize.width, height: role.hitSize.height)
        }
        .buttonStyle(.borderless)
        .controlSize(.mini)
        .help(label)
    }
}

private extension ClipDropIconActionButton.Role {
    var iconSize: CGFloat {
        switch self {
        case .primary:
            return 14
        case .secondary:
            return 13
        }
    }

    var hitSize: CGSize {
        switch self {
        case .primary:
            return CGSize(width: 24, height: 22)
        case .secondary:
            return CGSize(width: 22, height: 22)
        }
    }

    var foregroundStyle: Color {
        switch self {
        case .primary:
            return ClipDropDesignToken.Colors.brandColor
        case .secondary:
            return .secondary
        }
    }
}
