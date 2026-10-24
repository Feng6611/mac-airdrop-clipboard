import SwiftUI

struct ClipDropComposeView: View {
    @State private var text: String
    let send: (String) -> Void
    let cancel: () -> Void

    init(text: String, send: @escaping (String) -> Void, cancel: @escaping () -> Void) {
        _text = State(initialValue: text)
        self.send = send
        self.cancel = cancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $text)
                .font(.body)
                .accessibilityLabel("Message")
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                }

            HStack {
                Spacer()
                Button("Cancel", action: cancel)
                    .keyboardShortcut(.escape, modifiers: [])
                Button("Send") {
                    send(text)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 480, height: 300)
        .onExitCommand(perform: cancel)
    }
}
