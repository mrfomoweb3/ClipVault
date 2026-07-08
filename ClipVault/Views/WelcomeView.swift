import SwiftUI
import AppKit

struct WelcomeView: View {
    @State private var step: Step = .welcome
    @State private var axGranted = AXIsProcessTrusted()
    let onAddToMenuBar: () -> Void

    private let poll = Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()

    enum Step { case welcome, permission }

    var body: some View {
        ZStack {
            GridPaperBackground()
                .ignoresSafeArea()

            Group {
                if step == .welcome {
                    welcomePage
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    permissionPage
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .animation(.spring(duration: 0.38), value: step)
        }
        .frame(width: 480, height: 560)
        .onReceive(poll) { _ in axGranted = AXIsProcessTrusted() }
    }

    // MARK: - Welcome page

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            appIconView
                .padding(.bottom, 22)

            Text("ClipVault")
                .font(.cvDisplay(40))
                .foregroundStyle(Color.cvText)

            Text("Your clipboard. Remembered.")
                .font(.cvBodyMedium(15))
                .foregroundStyle(Color.cvTextSecond)
                .padding(.top, 6)

            VStack(spacing: 10) {
                featureRow(sf: "doc.on.clipboard.fill",
                           label: "Captures everything you copy, automatically")
                featureRow(sf: "magnifyingglass",
                           label: "Search your full history in an instant")
                featureRow(sf: "command",
                           label: "Open from any app with ⌘⇧V")
            }
            .padding(.top, 30)
            .padding(.horizontal, 44)

            Spacer()

            ctaButton(label: "Get Started", sf: "arrow.right") {
                withAnimation(.spring(duration: 0.38)) { step = .permission }
            }
            .padding(.bottom, 44)
        }
    }

    // MARK: - Permission page

    private var permissionPage: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 58))
                .foregroundStyle(Color.cvOrange)
                .symbolRenderingMode(.hierarchical)
                .padding(.bottom, 20)

            Text("One quick step")
                .font(.cvDisplay(28))
                .foregroundStyle(Color.cvText)

            Text("ClipVault needs Accessibility access\nto paste items back into your apps.")
                .font(.cvBody(13))
                .foregroundStyle(Color.cvTextSecond)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 8)

            accessibilityRow
                .padding(.top, 30)
                .padding(.horizontal, 44)

            Spacer()

            ctaButton(label: "Add to Menu Bar", sf: "menubar.arrow.up.rectangle") {
                onAddToMenuBar()
            }
            .opacity(axGranted ? 1 : 0.35)
            .disabled(!axGranted)

            if !axGranted {
                Button("Skip for now") { onAddToMenuBar() }
                    .buttonStyle(.plain)
                    .font(.cvBodyMedium(12))
                    .foregroundStyle(Color.cvTextSecond)
                    .padding(.top, 10)
            }

            Spacer().frame(height: 44)
        }
    }

    // MARK: - Reusable bits

    @ViewBuilder
    private var appIconView: some View {
        if let icon = NSImage(named: "AppIcon") {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.15), radius: 14, y: 5)
        }
    }

    private func featureRow(sf: String, label: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: sf)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.cvPurple)
                .frame(width: 26)
            Text(label)
                .font(.cvBody(13))
                .foregroundStyle(Color.cvText)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cvSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.cvBorder.opacity(0.9), lineWidth: 1.5)
        )
    }

    private var accessibilityRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "accessibility")
                .font(.system(size: 20))
                .foregroundStyle(Color.cvPurple)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text("Accessibility Access")
                    .font(.cvBodySemibold(13))
                    .foregroundStyle(Color.cvText)
                Text("Required to paste items into other apps")
                    .font(.cvBody(11))
                    .foregroundStyle(Color.cvTextSecond)
            }

            Spacer()

            if axGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 20))
                    .transition(.scale.combined(with: .opacity))
            } else {
                Button("Grant") {
                    NSWorkspace.shared.open(
                        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    )
                }
                .controlSize(.small)
                .buttonStyle(.borderedProminent)
            }
        }
        .animation(.spring(duration: 0.3), value: axGranted)
        .padding(16)
        .background(Color.cvSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.cvBorder.opacity(0.9), lineWidth: 1.5)
        )
    }

    private func ctaButton(label: String, sf: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ChunkyPill {
                HStack(spacing: 8) {
                    Text(label)
                        .font(.cvBodySemibold(15))
                    Image(systemName: sf)
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Color.cvText)
                .frame(width: 230, height: 48)
            }
        }
        .buttonStyle(.plain)
        .padding(.bottom, 3)   // room for the pill's offset shadow
    }
}
