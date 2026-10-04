import AppKit

/// Makes sure ClipVault runs from /Applications.
///
/// People often double-click the app straight from the mounted .dmg window
/// instead of dragging it to Applications. That copy lives on the disk image,
/// so the moment the DMG is ejected or deleted the app vanishes. On launch we
/// detect that case and offer to copy ourselves into /Applications, then
/// relaunch from there.
@MainActor
enum InstallLocationService {
    private static let destination = URL(fileURLWithPath: "/Applications/ClipVault.app")

    /// Returns `true` if a move was started and the app is about to quit —
    /// the caller should stop launching.
    static func moveToApplicationsIfNeeded() -> Bool {
        #if DEBUG
        return false   // Xcode runs from DerivedData; never nag during development.
        #else
        let source = Bundle.main.bundleURL
        guard needsMove(source) else { return false }

        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Move ClipVault to your Applications folder?"
        alert.informativeText = "ClipVault is running from the installer disk image. "
            + "If you don't move it, it will disappear when the disk image is ejected or deleted."
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Not Now")
        guard alert.runModal() == .alertFirstButtonReturn else { return false }

        do {
            try install(from: source)
        } catch {
            let fail = NSAlert()
            fail.messageText = "Couldn't move ClipVault"
            fail.informativeText = "Please drag ClipVault into your Applications folder manually.\n\n"
                + error.localizedDescription
            fail.runModal()
            return false
        }

        relaunch(ejecting: mountedVolume(of: source))
        return true
        #endif
    }

    // MARK: - Detection

    private static func needsMove(_ url: URL) -> Bool {
        let path = url.resolvingSymlinksInPath().path
        if path.hasPrefix("/Applications/") { return false }
        if path.hasPrefix(NSHomeDirectory() + "/Applications/") { return false }
        // Running from a mounted DMG, or from Gatekeeper's randomized
        // read-only "App Translocation" copy (happens when a quarantined app is
        // launched in place, e.g. from Downloads or the DMG).
        return path.hasPrefix("/Volumes/") || path.contains("/AppTranslocation/")
    }

    private static func mountedVolume(of url: URL) -> String? {
        let parts = url.path.split(separator: "/")
        guard parts.count >= 2, parts[0] == "Volumes" else { return nil }
        return "/Volumes/\(parts[1])"
    }

    // MARK: - Install

    private static func install(from source: URL) throws {
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: destination.path) {
                try fm.trashItem(at: destination, resultingItemURL: nil)
            }
            try fm.copyItem(at: source, to: destination)
            stripQuarantine()
        } catch {
            // /Applications isn't writable for non-admin users — ask for
            // an admin password and do the same thing with elevated rights.
            try installWithAdminPrivileges(from: source)
        }
    }

    private static func installWithAdminPrivileges(from source: URL) throws {
        let src = shellQuote(source.path)
        let dst = shellQuote(destination.path)
        let command = "rm -rf \(dst) && cp -R \(src) \(dst) && xattr -dr com.apple.quarantine \(dst)"
        let script = "do shell script \"\(command.replacingOccurrences(of: "\"", with: "\\\""))\" with administrator privileges"

        var errorInfo: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            throw NSError(domain: "ClipVault.Install", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    /// Without this, the fresh copy can get translocated again on next launch.
    private static func stripQuarantine() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
        task.arguments = ["-dr", "com.apple.quarantine", destination.path]
        try? task.run()
        task.waitUntilExit()
    }

    // MARK: - Relaunch

    /// Waits for this process to exit, opens the installed copy, then ejects
    /// the installer DMG so the user isn't left with it mounted.
    private static func relaunch(ejecting volume: String?) {
        let pid = ProcessInfo.processInfo.processIdentifier
        var script = "while kill -0 \(pid) 2>/dev/null; do sleep 0.2; done; open \(shellQuote(destination.path))"
        if let volume {
            script += "; sleep 1; hdiutil detach \(shellQuote(volume)) -quiet"
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", script]
        try? task.run()
        NSApp.terminate(nil)
    }

    private static func shellQuote(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
