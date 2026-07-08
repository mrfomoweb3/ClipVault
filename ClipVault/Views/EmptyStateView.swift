import SwiftUI

struct EmptyStateView: View {
    var isFiltered: Bool = false

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.cvYellow.opacity(0.25))
                    .frame(width: 84, height: 84)
                Circle()
                    .strokeBorder(Color.cvBorder.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 84, height: 84)
                Image(systemName: isFiltered ? "magnifyingglass" : "tray")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.cvText)
            }

            Text(isFiltered ? "No results" : "Nothing copied yet")
                .font(.cvDisplaySemi(18))
                .foregroundStyle(Color.cvText)

            Text(isFiltered ? "Try a different search term" : "Copy something and it'll\nland right here.")
                .font(.cvBody(12))
                .foregroundStyle(Color.cvTextSecond)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
