import SwiftUI

struct NotesGalleryView: View {
    @Bindable var vm: ClipboardViewModel
    let onOpen: (StickyNote) -> Void
    let onCreate: (NoteColor) -> Void
    let onDelete: (StickyNote) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(vm.notes.isEmpty ? "A little space for big thoughts." : "Your desk, minus the clutter.")
                    .font(.cvBodyMedium(11))
                    .foregroundStyle(Color.cvTextSecond)
                Spacer()
                Menu {
                    ForEach(NoteColor.allCases) { color in
                        Button(color.name) { onCreate(color) }
                    }
                } label: {
                    Label("New note", systemImage: "plus")
                        .font(.cvBodySemibold(11))
                        .foregroundStyle(Color.cvText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color.cvYellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.cvBorder, lineWidth: 1.5))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            if vm.notes.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5).fill(NoteColor.sky.paper).frame(width: 70, height: 70).rotationEffect(.degrees(7))
                        RoundedRectangle(cornerRadius: 5).fill(NoteColor.lemon.paper).frame(width: 70, height: 70).rotationEffect(.degrees(-6)).offset(x: -15, y: 5)
                        Image(systemName: "plus").font(.system(size: 20, weight: .bold)).foregroundStyle(Color.cvText)
                    }
                    Text("Pin your first thought")
                        .font(.cvDisplaySemi(18))
                        .foregroundStyle(Color.cvText)
                    Text("Notes stay on your desktop and come back after relaunch.")
                        .font(.cvBody(11))
                        .foregroundStyle(Color.cvTextSecond)
                        .multilineTextAlignment(.center)
                        .frame(width: 230)
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(vm.notes, id: \.id) { note in
                            noteCard(note)
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    private func noteCard(_ note: StickyNote) -> some View {
        Button { onOpen(note) } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle().fill(Color.cvText.opacity(0.15)).frame(width: 5, height: 5)
                    Spacer()
                    Image(systemName: note.isVisible ? "eye.fill" : "eye.slash")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.cvText.opacity(0.5))
                }
                Text(note.text.isEmpty ? "New thought…" : note.text)
                    .font(.cvBodyMedium(12))
                    .foregroundStyle(Color.cvText.opacity(note.text.isEmpty ? 0.45 : 0.9))
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, minHeight: 58, alignment: .topLeading)
                Text(note.updatedAt.relativeString())
                    .font(.cvBody(9))
                    .foregroundStyle(Color.cvText.opacity(0.45))
            }
            .padding(12)
            .background(note.color.paper)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.cvBorder.opacity(0.16), lineWidth: 1))
            .shadow(color: Color.cvBorder.opacity(0.12), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) { onDelete(note) } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
