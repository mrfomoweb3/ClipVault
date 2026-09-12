import SwiftUI
import AppKit

@MainActor
final class RichNoteEditingController: ObservableObject {
    weak var textView: NSTextView?

    func toggleBold() { mutateFont { NSFontManager.shared.convert($0, toHaveTrait: .boldFontMask) } }
    func toggleItalic() { mutateFont { NSFontManager.shared.convert($0, toHaveTrait: .italicFontMask) } }
    func toggleUnderline() {
        guard let currentTextView = textView else { return }
        let active = (currentTextView.typingAttributes[.underlineStyle] as? Int ?? 0) != 0
        applyAttribute(.underlineStyle, value: active ? 0 : NSUnderlineStyle.single.rawValue)
    }

    func applyFont(_ name: String) {
        guard let textView else { return }
        let size = currentFont().pointSize
        let font = NSFont(name: name, size: size) ?? .systemFont(ofSize: size)
        applyAttribute(.font, value: font)
    }

    func changeSize(_ delta: CGFloat) {
        let current = currentFont()
        let size = min(44, max(11, current.pointSize + delta))
        applyAttribute(.font, value: NSFontManager.shared.convert(current, toSize: size))
    }

    func highlight(_ color: NSColor?) {
        applyAttribute(.backgroundColor, value: color ?? .clear)
    }

    func align(_ alignment: NSTextAlignment) {
        guard let textView else { return }
        textView.setAlignment(alignment, range: effectiveRange())
    }

    func insertList(numbered: Bool) {
        guard let textView else { return }
        let range = textView.rangeForUserTextChange
        let source = range.length > 0 ? (textView.string as NSString).substring(with: range) : ""
        let lines = (source.isEmpty ? [""] : source.components(separatedBy: .newlines))
        let formatted = lines.enumerated().map { index, line in
            numbered ? "\(index + 1). \(line)" : "• \(line)"
        }.joined(separator: "\n")
        textView.insertText(formatted, replacementRange: range)
    }

    private func mutateFont(_ transform: (NSFont) -> NSFont) {
        applyAttribute(.font, value: transform(currentFont()))
    }

    private func currentFont() -> NSFont {
        guard let textView else { return .systemFont(ofSize: 16) }
        if textView.selectedRange().length > 0,
           let font = textView.textStorage?.attribute(.font, at: textView.selectedRange().location, effectiveRange: nil) as? NSFont {
            return font
        }
        return textView.typingAttributes[.font] as? NSFont ?? .systemFont(ofSize: 16)
    }

    private func effectiveRange() -> NSRange {
        guard let textView else { return .init() }
        let selected = textView.selectedRange()
        return selected.length > 0 ? selected : NSRange(location: selected.location, length: 0)
    }

    private func applyAttribute(_ key: NSAttributedString.Key, value: Any) {
        guard let textView else { return }
        let range = textView.selectedRange()
        if range.length > 0 {
            textView.textStorage?.addAttribute(key, value: value, range: range)
        }
        textView.typingAttributes[key] = value
        textView.didChangeText()
    }
}

struct RichNoteEditor: NSViewRepresentable {
    @Binding var richTextData: Data?
    let initialText: String
    let paperColor: NSColor
    let controller: RichNoteEditingController
    let onChange: (String, Data) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 18, height: 16)
        textView.font = NSFont(name: "Noteworthy", size: 18) ?? .systemFont(ofSize: 17)
        textView.textColor = NSColor(calibratedWhite: 0.12, alpha: 0.9)
        textView.insertionPointColor = .black
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        if let richTextData,
           let attributed = try? NSAttributedString(data: richTextData, options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil) {
            textView.textStorage?.setAttributedString(attributed)
        } else {
            textView.string = initialText
        }

        scroll.documentView = textView
        controller.textView = textView
        DispatchQueue.main.async { textView.window?.makeFirstResponder(textView) }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        guard let textView = scroll.documentView as? NSTextView else { return }
        textView.backgroundColor = paperColor
        controller.textView = textView
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichNoteEditor
        init(parent: RichNoteEditor) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView,
                  let storage = textView.textStorage,
                  let data = try? storage.data(from: NSRange(location: 0, length: storage.length),
                                               documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) else { return }
            parent.richTextData = data
            parent.onChange(textView.string, data)
        }
    }
}
