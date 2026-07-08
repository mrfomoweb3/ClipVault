import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("maxItems")       private var maxItems: Int    = 200
    @AppStorage("autoDeleteDays") private var autoDeleteDays: Int = 30
    @AppStorage("launchAtLogin")  private var launchAtLogin: Bool = false
    @AppStorage("ignorePasswords")private var ignorePasswords: Bool = true
    @AppStorage("iconStyle")      private var iconStyle: Int   = 0

    @State private var showClearConfirm = false

    @Environment(ClipboardViewModel.self) private var vm

    var body: some View {
        TabView {
            generalTab.tabItem { Label("General", systemImage: "gearshape") }
            historyTab.tabItem { Label("History", systemImage: "clock") }
            privacyTab.tabItem { Label("Privacy", systemImage: "hand.raised") }
        }
        .padding(20)
        .frame(width: 420, height: 320)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section("Appearance") {
                Picker("Menu Bar Icon", selection: $iconStyle) {
                    Text("Icon").tag(0)
                    Text("Icon + Count").tag(1)
                }
                .pickerStyle(.segmented)
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, value in
                        applyLaunchAtLogin(value)
                    }
            }

            Section("Updates") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ClipVault \(appVersion)")
                            .font(.system(size: 13, weight: .medium))
                        Text("Automatically checks for updates")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Check for Updates…") {
                        NSApp.sendAction(Selector(("checkForUpdates:")), to: nil, from: nil)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    // MARK: - History

    private var historyTab: some View {
        Form {
            Section("Storage") {
                Picker("Max Items", selection: $maxItems) {
                    Text("50").tag(50)
                    Text("100").tag(100)
                    Text("200").tag(200)
                    Text("500").tag(500)
                }

                Picker("Auto-Delete After", selection: $autoDeleteDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                    Text("Never").tag(0)
                }
            }

            Section("Danger Zone") {
                Button("Clear All History…", role: .destructive) {
                    showClearConfirm = true
                }
                .confirmationDialog(
                    "Clear all clipboard history?",
                    isPresented: $showClearConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Clear All", role: .destructive) { vm.clearAll() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This cannot be undone. Pinned items will also be removed.")
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Privacy

    private var privacyTab: some View {
        Form {
            Section("Filters") {
                Toggle("Ignore Passwords & Secure Fields", isOn: $ignorePasswords)
            }

            Section("Accessibility Permission") {
                HStack {
                    Image(systemName: AXIsProcessTrusted() ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(AXIsProcessTrusted() ? Color.green : Color.orange)
                    Text(AXIsProcessTrusted() ? "Permission granted" : "Permission required")
                        .font(.system(size: 13))

                    Spacer()

                    if !AXIsProcessTrusted() {
                        Button("Grant Access") {
                            NSWorkspace.shared.open(
                                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.cvPurple)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // ignore — not critical
        }
    }
}
