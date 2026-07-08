import Carbon
import AppKit
import os

// Bridges the Carbon C callback into Swift — nonisolated global required by C API
nonisolated(unsafe) private var hotkeyCallback: (() -> Void)?

private func hotKeyHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    hotkeyCallback?()
    return noErr
}

@MainActor
final class HotkeyManager {
    private let logger = Logger(subsystem: "com.clipvault.app", category: "Hotkey")
    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    var onActivate: (() -> Void)?

    func register() {
        hotkeyCallback = { [weak self] in
            Task { @MainActor in self?.onActivate?() }
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyHandler,
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )

        // Cmd+Shift+V  → modifiers: cmdKey | shiftKey, keyCode: kVK_ANSI_V = 9
        var hotKeyID = EventHotKeyID(signature: OSType(bitPattern: 0x4356_4C54), id: 1) // "CVLT"
        RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            OptionBits(0),
            &hotKeyRef
        )

        logger.info("Hotkey Cmd+Shift+V registered")
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
        hotKeyRef = nil
        eventHandlerRef = nil
        hotkeyCallback = nil
    }
}
