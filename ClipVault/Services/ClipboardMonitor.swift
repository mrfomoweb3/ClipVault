import AppKit
import Foundation
import os

// Sendable value type for crossing actor boundaries
struct ClipboardCapture: Sendable {
    let content: String
    let contentType: ClipboardType
    var imageData: Data? = nil
}

actor ClipboardMonitor {
    private let logger = Logger(subsystem: "com.clipvault.app", category: "Monitor")
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var monitorTask: Task<Void, Never>?

    private var onNewCapture: (@MainActor @Sendable (ClipboardCapture) -> Void)?

    func setCallback(_ callback: @escaping @MainActor @Sendable (ClipboardCapture) -> Void) {
        onNewCapture = callback
    }

    func start() {
        monitorTask?.cancel()
        monitorTask = Task {
            while !Task.isCancelled {
                await checkPasteboard()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    func stop() {
        monitorTask?.cancel()
        monitorTask = nil
    }

    private func checkPasteboard() async {
        let pb = NSPasteboard.general
        let current = pb.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        guard let capture = read(from: pb) else { return }
        let callback = onNewCapture
        await MainActor.run { callback?(capture) }
    }

    private func read(from pb: NSPasteboard) -> ClipboardCapture? {
        if let str = pb.string(forType: .string),
           !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ClipboardCapture(content: str, contentType: classify(str))
        }

        if let png = imagePNG(from: pb) {
            let label: String
            if let rep = NSBitmapImageRep(data: png) {
                label = "Image · \(rep.pixelsWide) × \(rep.pixelsHigh)"
            } else {
                label = "Image"
            }
            return ClipboardCapture(content: label, contentType: .image, imageData: png)
        }

        if let urls = pb.readObjects(forClasses: [NSURL.self]) as? [URL], let first = urls.first {
            return ClipboardCapture(content: first.absoluteString, contentType: .url)
        }

        return nil
    }

    /// Returns copied image content as PNG bytes, converting from TIFF if needed.
    private func imagePNG(from pb: NSPasteboard) -> Data? {
        if let png = pb.data(forType: .png) { return png }
        if let tiff = pb.data(forType: .tiff),
           let rep = NSBitmapImageRep(data: tiff) {
            return rep.representation(using: .png, properties: [:])
        }
        return nil
    }

    private func classify(_ text: String) -> ClipboardType {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if t.hasPrefix("http://") || t.hasPrefix("https://") || t.hasPrefix("ftp://") {
            return .url
        }
        if t.hasPrefix("/") || t.hasPrefix("~/") {
            return .filePath
        }
        let codeKeywords = ["func ", "class ", "import ", "def ", "const ", "var ", "let ",
                            "=>", "->", "return ", "if (", "for ("]
        if text.contains("\n") && codeKeywords.contains(where: { t.contains($0) }) {
            return .code
        }
        return .text
    }
}
