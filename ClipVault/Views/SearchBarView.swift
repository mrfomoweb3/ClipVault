import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(text.isEmpty ? Color.cvTextSecond : Color.cvText)

            TextField("Search history…", text: $text)
                .textFieldStyle(.plain)
                .font(.cvBody(13))
                .foregroundStyle(Color.cvText)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.cvTextSecond)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.cvSearchBg)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(isFocused ? Color.cvPurple : Color.cvBorder.opacity(0.35),
                              lineWidth: isFocused ? 2 : 1.5)
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: text.isEmpty)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isFocused)
    }
}
