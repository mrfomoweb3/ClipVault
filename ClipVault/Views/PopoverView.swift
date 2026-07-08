import SwiftUI

struct PopoverView: View {
    @Bindable var vm: ClipboardViewModel
    let onClose: () -> Void

    // Live-tracked so the "grant access" banner disappears the moment the
    // user grants Accessibility — AXIsProcessTrusted() isn't observable, so
    // we poll it and re-check whenever the popover appears.
    @State private var axTrusted = AXIsProcessTrusted()
    private let axPoll = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            if !axTrusted {
                accessibilityBanner
            }
            searchArea
            Rectangle().fill(Color.cvDivider).frame(height: 1)
            ClipboardListView(vm: vm) { entry in
                onClose()
                Task { await vm.paste(entry) }
            }
            Rectangle().fill(Color.cvDivider).frame(height: 1)
            footerBar
        }
        .frame(width: 380, height: 520)
        .background(GridPaperBackground())
        .animation(.easeInOut(duration: 0.25), value: axTrusted)
        .onAppear { axTrusted = AXIsProcessTrusted() }
        .onReceive(axPoll) { _ in
            let now = AXIsProcessTrusted()
            if now != axTrusted { axTrusted = now }
        }
        .focusable()
        .onKeyPress(.downArrow)  { vm.selectNext();     return .handled }
        .onKeyPress(.upArrow)    { vm.selectPrevious(); return .handled }
        .onKeyPress(.return) {
            let close = onClose
            Task { close(); await vm.pasteSelected() }
            return .handled
        }
        .onKeyPress(.escape) { onClose(); return .handled }
    }

    // MARK: - Accessibility banner

    private var accessibilityBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white)
            Text("Accessibility permission required to paste")
                .font(.cvBodyMedium(11))
                .foregroundStyle(.white)
            Spacer()
            Button("Grant") {
                NSWorkspace.shared.open(
                    URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                )
            }
            .font(.cvBodySemibold(11))
            .foregroundStyle(Color.cvText)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(Color.cvYellow)
            .clipShape(Capsule())
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.cvOrange)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 8) {
            if let logo = NSImage(named: "AppIcon") {
                Image(nsImage: logo)
                    .resizable()
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            Text("ClipVault")
                .font(.cvDisplay(19))
                .foregroundStyle(Color.cvText)
            Spacer()
            Text("\(vm.filteredEntries.count)")
                .font(.cvBodyBold(11))
                .foregroundStyle(Color.cvText)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Color.cvYellow)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.cvBorder, lineWidth: 1.5))
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
    }

    // MARK: - Search

    private var searchArea: some View {
        SearchBarView(text: $vm.searchText)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack(spacing: 14) {
            shortcutHint("↑↓", label: "Navigate")
            shortcutHint("↩", label: "Paste")
            shortcutHint("⎋", label: "Close")
            Spacer()
            Button("Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .buttonStyle(.plain)
            .font(.cvBodyMedium(11))
            .foregroundStyle(Color.cvTextSecond)
        }
        .padding(.horizontal, 14)
        .frame(height: 36)
    }

    private func shortcutHint(_ key: String, label: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.cvText)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.cvSurface)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.cvBorder.opacity(0.25), lineWidth: 1)
                )
            Text(label)
                .font(.cvBody(10))
                .foregroundStyle(Color.cvTextSecond)
        }
    }
}
