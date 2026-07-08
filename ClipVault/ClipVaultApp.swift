import SwiftUI
import SwiftData
import AppKit
import Carbon
import CoreText
import Sparkle

@main
struct ClipVaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(delegate.viewModel)
        }
    }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var viewModel: ClipboardViewModel!
    private var storage: StorageService!
    private let hotkeyManager = HotkeyManager()
    private var eventMonitor: Any?
    private var welcomeWindow: NSWindow?

    // Sparkle: checks the appcast feed and installs updates. Automatic
    // background checks are enabled via SUEnableAutomaticChecks in Info.plist.
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    /// Wired to the "Check for Updates…" button in Settings via the responder chain.
    @objc func checkForUpdates(_ sender: Any?) {
        updaterController.checkForUpdates(sender)
    }

    private var hasOnboarded: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding") }
    }

    /// Registers every bundled .ttf with CoreText so the Fredoka/Poppins
    /// custom fonts resolve regardless of where the build system placed them.
    private func registerBundledFonts() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) else { return }
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerBundledFonts()

        do {
            storage = try StorageService()
        } catch {
            fatalError("SwiftData init failed: \(error)")
        }

        viewModel = ClipboardViewModel(storage: storage)

        // Show the ClipVault logo as the Dock icon.
        NSApp.applicationIconImage = NSImage(named: "AppIcon")

        if hasOnboarded {
            setupMenuBar()
            setupPopover()
            setupHotkey()
            // Menu-bar-only: no Dock icon, no app-switcher entry.
            NSApp.setActivationPolicy(.accessory)
        } else {
            // Regular only during onboarding so the welcome window is visible.
            NSApp.setActivationPolicy(.regular)
            showWelcomeWindow()
        }
    }

    // MARK: - Welcome window

    private func showWelcomeWindow() {
        let view = WelcomeView { [weak self] in self?.completeOnboarding() }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = NSHostingController(rootView: view)
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        welcomeWindow = window
    }

    func completeOnboarding() {
        hasOnboarded = true
        setupMenuBar()
        setupPopover()
        setupHotkey()
        welcomeWindow?.close()
        welcomeWindow = nil
        // Drop the Dock icon once onboarding is done — live in the menu bar only.
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregister()
        removeEventMonitor()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Quit if the welcome window is closed before onboarding completes
        return !hasOnboarded
    }

    // MARK: - Menu Bar

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            // Show the ClipVault logo in the menu bar. Fall back to an SF Symbol
            // if the asset can't be loaded for any reason.
            if let logo = NSImage(named: "AppIcon"), let sized = logo.copy() as? NSImage {
                sized.size = NSSize(width: 18, height: 18)
                sized.isTemplate = false   // keep the logo's real colors
                button.image = sized
            } else {
                button.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                       accessibilityDescription: "ClipVault")
                button.image?.isTemplate = true
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        let pop = NSPopover()
        pop.contentSize = NSSize(width: 380, height: 520)
        // .applicationDefined lets us control dismiss ourselves — avoids
        // the Sequoia bug where NSApp.activate fires an "outside-click"
        // that immediately closes a .transient popover.
        pop.behavior = .applicationDefined
        pop.animates = true
        pop.contentViewController = NSHostingController(
            rootView: PopoverView(vm: viewModel, onClose: { [weak self] in
                self?.closePopover()
            })
        )
        popover = pop
    }

    @objc func togglePopover() {
        guard let pop = popover, let button = statusItem?.button else { return }
        if pop.isShown {
            closePopover()
        } else {
            openPopover(from: button)
        }
    }

    private func openPopover(from button: NSButton) {
        guard let pop = popover else { return }

        // Remember what the user was working in before ClipVault opened
        viewModel.pasteService.targetApp = NSWorkspace.shared.frontmostApplication

        pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Activate so the search field and keyboard nav work inside the popover
        NSApp.activate(ignoringOtherApps: true)

        // Close when user clicks anywhere outside the popover
        addEventMonitor()
    }

    func closePopover() {
        popover?.performClose(nil)
        removeEventMonitor()
    }

    // MARK: - Outside-click monitor

    private func addEventMonitor() {
        removeEventMonitor()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func removeEventMonitor() {
        if let m = eventMonitor {
            NSEvent.removeMonitor(m)
            eventMonitor = nil
        }
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        hotkeyManager.onActivate = { [weak self] in
            self?.togglePopover()
        }
        hotkeyManager.register()
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let w = notification.object as? NSWindow, w === welcomeWindow else { return }
        welcomeWindow = nil
    }
}
