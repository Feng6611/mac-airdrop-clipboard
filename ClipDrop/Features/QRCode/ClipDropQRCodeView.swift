import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

enum ClipDropQRCodeGenerator {
    static let maximumByteCountAtCorrectionLevelM = 2_331

    static func canEncode(_ text: String) -> Bool {
        !text.isEmpty && Data(text.utf8).count <= maximumByteCountAtCorrectionLevelM
    }

    static func image(for text: String) -> NSImage? {
        guard canEncode(text) else { return nil }
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }

        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}

struct ClipDropQRCodeView: View {
    let content: String
    let copy: () -> Void

    private let qrImage: NSImage?

    init(content: String, copy: @escaping () -> Void) {
        self.content = content
        self.copy = copy
        self.qrImage = ClipDropQRCodeGenerator.image(for: content)
    }

    var body: some View {
        VStack(spacing: 14) {
            if let qrImage {
                Image(nsImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .accessibilityLabel("QR code")
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "qrcode")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("This content is too long for a QR code.")
                        .font(.headline)
                    Text("Copy shorter text or a shorter link, then try again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 300, height: 300)
            }

            Text(content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Spacer()
                Button("Copy", action: copy)
                    .keyboardShortcut("c", modifiers: .command)
            }
        }
        .padding(18)
        .frame(width: 360, height: 430)
    }
}
