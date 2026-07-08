import AppKit
import CoreGraphics
import Foundation
import os

@MainActor
final class PasteService {
    private let logger = Logger(subsystem: "com.clipvault.app", category: "Paste")

    // Set this to the frontmost app just before opening the popover
    var targetApp: NSRunningApplication?

    func paste(content: String, imageData: Data? = nil) async {
        // Always write to pasteboard — at minimum the user can Cmd+V themselves
        let pb = NSPasteboard.general
        pb.clearContents()
        if let imageData {
            pb.setData(imageData, forType: .png)
        } else {
            pb.setString(content, forType: .string)
        }

        guard AXIsProcessTrusted() else {
            logger.warning("Accessibility not granted — content is on pasteboard, use Cmd+V manually")
            return
        }

        guard let app = targetApp else {
            logger.warning("No target app captured — cannot auto-paste")
            return
        }

        logger.info("Pasting to: \(app.localizedName ?? "unknown") (pid \(app.processIdentifier))")

        // Let the popover finish closing before we switch apps
        try? await Task.sleep(for: .milliseconds(80))

        // Re-activate the app that was frontmost before ClipVault opened
        app.activate(options: .activateIgnoringOtherApps)

        // Wait for the OS to complete the app switch and key window to settle
        try? await Task.sleep(for: .milliseconds(250))

        sendCmdV()
    }

    func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options: CFDictionary = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func sendCmdV() {
        let src = CGEventSource(stateID: .hidSystemState)
        let vKey: CGKeyCode = 0x09

        guard
            let keyDown = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true),
            let keyUp   = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        else { return }

        keyDown.flags = .maskCommand
        keyUp.flags   = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }
}
