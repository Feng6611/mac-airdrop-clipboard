import SwiftUI

struct ClipDropIconActionButton: View {
    let systemName: String
    let label: String
    let controlSize: ControlSize
    let action: () -> Void

    init(
        systemName: String,
        label: String,
        controlSize: ControlSize = .small,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.label = label
        self.controlSize = controlSize
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.medium))
                .symbolRenderingMode(.hierarchical)
                .frame(
                    width: ClipDropDesignToken.Size.iconButtonHit,
                    height: ClipDropDesignToken.Size.iconButtonHit
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .controlSize(controlSize)
        .foregroundStyle(.secondary)
        .accessibilityLabel(Text(label))
        .help(label)
    }
}
