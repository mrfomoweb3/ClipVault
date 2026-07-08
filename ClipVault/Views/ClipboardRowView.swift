import SwiftUI

struct ClipboardRowView: View {
    let entry: ClipboardEntry
    let isSelected: Bool
    let onTap: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    private var bg: Color {
        if isSelected { return .cvSelected }
        if isHovered  { return .cvHover }
        return .clear
    }

    private var primaryFg: Color   { isSelected ? .white : .cvText }
    private var secondaryFg: Color { isSelected ? .white.opacity(0.7) : .cvTextSecond }
    private var iconFg: Color      { isSelected ? .white : .cvText }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Type icon — or a live thumbnail for images
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.18) : Color.cvSurface)
                        .frame(width: 32, height: 32)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(isSelected ? Color.clear : Color.cvBorder.opacity(0.18), lineWidth: 1)
                        )

                    if entry.contentType == .image,
                       let data = entry.imageData,
                       let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        Image(systemName: entry.contentType.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(iconFg)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.preview.truncated(to: 60))
                        .font(.cvBodyMedium(13))
                        .foregroundStyle(primaryFg)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 6) {
                        if let app = entry.appName, !app.isEmpty {
                            Text(app)
                                .font(.cvBody(10))
                                .foregroundStyle(secondaryFg)
                        }
                        Text(entry.timestamp.relativeString())
                            .font(.cvBody(10))
                            .foregroundStyle(secondaryFg)
                    }
                }

                Spacer()

                // Pin badge
                if entry.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(isSelected ? .white : Color.cvPin)
                        .rotationEffect(.degrees(45))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(bg)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button {
                onPin()
            } label: {
                Label(entry.isPinned ? "Unpin" : "Pin", systemImage: entry.isPinned ? "pin.slash" : "pin")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .help(entry.content)
    }
}
