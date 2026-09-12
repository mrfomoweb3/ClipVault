import SwiftUI
import AppKit

struct StickyNoteWindowView: View {
    @Bindable var note: StickyNote
    let onChange: () -> Void
    let onClose: () -> Void
    let onDelete: () -> Void

    @StateObject private var editor = RichNoteEditingController()
    @State private var showColors = false
    @State private var showHighlight = false
    @State private var didSave = false

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            formattingBar
            Rectangle().fill(Color.cvText.opacity(0.24)).frame(height: 1)
            RichNoteEditor(
                richTextData: $note.richTextData,
                initialText: note.text,
                paperColor: NSColor(note.color.paper),
                controller: editor
            ) { plainText, data in
                note.text = plainText
                note.richTextData = data
                onChange()
            }
        }
        .background(note.color.paper)
    }

    private var titleBar: some View {
        HStack(spacing: 8) {
            Button(action: onClose) {
                Image(systemName: "xmark").font(.system(size: 9, weight: .bold))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.58))
                    .overlay(Circle().strokeBorder(Color.cvText.opacity(0.18), lineWidth: 1))
                    .clipShape(Circle())
            }
            .help("Put away")

            Text("ClipVault note")
                .font(.cvDisplaySemi(14))
                .foregroundStyle(Color.cvText.opacity(0.92))

            Spacer()

            Button {
                onChange()
                didSave = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.4))
                    didSave = false
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: didSave ? "checkmark" : "square.and.arrow.down")
                    Text(didSave ? "Saved" : "Save")
                }
                .font(.cvBodySemibold(10))
                .foregroundStyle(didSave ? Color.cvText : Color.white)
                .padding(.horizontal, 10)
                .frame(height: 26)
                .background(didSave ? Color.white.opacity(0.5) : Color.cvPurple)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .help("Save note")

            Button { showColors.toggle() } label: {
                HStack(spacing: 5) {
                    Circle().fill(note.color.paper).frame(width: 13, height: 13)
                        .overlay(Circle().strokeBorder(Color.cvText.opacity(0.35), lineWidth: 1))
                    Text(note.color.name).font(.cvBodySemibold(9))
                }
                .padding(.horizontal, 8).frame(height: 24)
                .background(Color.white.opacity(0.58)).clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.cvText.opacity(0.16), lineWidth: 1))
            }
            .popover(isPresented: $showColors, arrowEdge: .bottom) {
                HStack(spacing: 10) {
                    ForEach(NoteColor.allCases) { color in
                        Button {
                            note.color = color
                            onChange()
                            showColors = false
                        } label: {
                            Circle().fill(color.paper).frame(width: 26, height: 26)
                                .overlay(Circle().strokeBorder(note.color == color ? Color.cvText : .clear, lineWidth: 2))
                        }.buttonStyle(.plain).help(color.name)
                    }
                }.padding(12)
            }

            Menu {
                Button(role: .destructive, action: onDelete) { Label("Delete note", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 11, weight: .bold)).frame(width: 22, height: 22)
            }
            .menuStyle(.borderlessButton).frame(width: 24)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.cvText.opacity(0.88))
        .padding(.horizontal, 10)
        .frame(height: 40)
    }

    private var formattingBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                Menu {
                    fontButton("Noteworthy", label: "Neat handwriting")
                    fontButton("Bradley Hand", label: "Casual handwriting")
                    fontButton("Marker Felt", label: "Marker")
                    fontButton("Chalkboard", label: "Chalkboard")
                    fontButton("Poppins-Medium", label: "Clean")
                } label: {
                    Label("Style", systemImage: "textformat").toolbarChip(wide: true)
                }
                .menuStyle(.borderlessButton).fixedSize()

                divider
                formatButton("bold", help: "Bold") { editor.toggleBold() }
                formatButton("italic", help: "Italic") { editor.toggleItalic() }
                formatButton("underline", help: "Underline") { editor.toggleUnderline() }
                divider
                formatButton("textformat.size.smaller", help: "Smaller text") { editor.changeSize(-2) }
                formatButton("textformat.size.larger", help: "Larger text") { editor.changeSize(2) }

                Menu {
                    highlightButton("Yellow", color: .systemYellow)
                    highlightButton("Mint", color: .systemMint)
                    highlightButton("Pink", color: .systemPink)
                    highlightButton("Blue", color: .systemBlue.withAlphaComponent(0.35))
                    Button("Remove highlight") { editor.highlight(nil) }
                } label: {
                    Image(systemName: "highlighter").toolbarChip()
                }
                .menuStyle(.borderlessButton).fixedSize()

                divider
                formatButton("list.bullet", help: "Bulleted list") { editor.insertList(numbered: false) }
                formatButton("list.number", help: "Numbered list") { editor.insertList(numbered: true) }
                Menu {
                    Button("Align left") { editor.align(.left) }
                    Button("Align center") { editor.align(.center) }
                    Button("Align right") { editor.align(.right) }
                } label: {
                    Image(systemName: "text.alignleft").toolbarChip()
                }
                .menuStyle(.borderlessButton).fixedSize()
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 38)
        .background(Color.white.opacity(0.46))
    }

    private var divider: some View {
        Rectangle().fill(Color.cvText.opacity(0.25)).frame(width: 1, height: 18).padding(.horizontal, 2)
    }

    private func formatButton(_ icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).toolbarChip() }.buttonStyle(.plain).help(help)
    }

    private func fontButton(_ font: String, label: String) -> some View {
        Button(label) { editor.applyFont(font) }
    }

    private func highlightButton(_ label: String, color: NSColor) -> some View {
        Button(label) { editor.highlight(color.withAlphaComponent(0.5)) }
    }
}

private extension View {
    func toolbarChip(wide: Bool = false) -> some View {
        self.font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.cvText.opacity(0.92))
            .frame(minWidth: wide ? 52 : 28, minHeight: 26)
            .padding(.horizontal, wide ? 5 : 0)
            .background(Color.white.opacity(0.62))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.cvText.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
