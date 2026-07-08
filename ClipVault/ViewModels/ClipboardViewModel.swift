import SwiftUI
import SwiftData
import os

@MainActor
@Observable
final class ClipboardViewModel {
    private let logger = Logger(subsystem: "com.clipvault.app", category: "ViewModel")

    var entries: [ClipboardEntry] = []
    var searchText: String = ""
    var selectedID: UUID? = nil

    var filteredEntries: [ClipboardEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            ($0.appName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private let storage: StorageService
    private let monitor = ClipboardMonitor()
    let pasteService = PasteService()

    // User preferences
    var maxItems: Int {
        get { UserDefaults.standard.integer(forKey: "maxItems").nonZero(default: 200) }
        set { UserDefaults.standard.set(newValue, forKey: "maxItems") }
    }

    var autoDeleteDays: Int {
        get { UserDefaults.standard.integer(forKey: "autoDeleteDays").nonZero(default: 30) }
        set { UserDefaults.standard.set(newValue, forKey: "autoDeleteDays") }
    }

    init(storage: StorageService) {
        self.storage = storage
        load()
        startMonitor()
        scheduleCleanup()
        pasteService.requestAccessibilityIfNeeded()
    }

    // MARK: - Load

    func load() {
        entries = storage.fetchAll(limit: maxItems)
    }

    // MARK: - Monitor

    private func startMonitor() {
        Task {
            await monitor.setCallback { @MainActor [weak self] capture in
                self?.handleNew(capture)
            }
            await monitor.start()
        }
    }

    private func handleNew(_ capture: ClipboardCapture) {
        // Images dedupe on their pixel data; everything else on its text.
        let existing: ClipboardEntry?
        if capture.contentType == .image, let data = capture.imageData {
            existing = entries.first { $0.contentType == .image && $0.imageData == data }
        } else {
            existing = entries.first { $0.content == capture.content && $0.contentType == capture.contentType }
        }

        if let existing {
            existing.timestamp = Date()
            entries.removeAll { $0.id == existing.id }
            entries.insert(existing, at: 0)
            try? storage.context.save()
            return
        }

        let entry = ClipboardEntry(content: capture.content,
                                   contentType: capture.contentType,
                                   imageData: capture.imageData)
        storage.save(entry)
        entries.insert(entry, at: 0)

        if entries.count > maxItems {
            let overflow = Array(entries.dropFirst(maxItems).filter { !$0.isPinned })
            overflow.forEach { item in
                storage.delete(item)
                entries.removeAll { $0.id == item.id }
            }
        }

        load()
    }

    // MARK: - Actions

    func paste(_ entry: ClipboardEntry) async {
        await pasteService.paste(content: entry.content, imageData: entry.imageData)
    }

    func togglePin(_ entry: ClipboardEntry) {
        entry.isPinned.toggle()
        try? storage.context.save()
        load()
    }

    func delete(_ entry: ClipboardEntry) {
        storage.delete(entry)
        entries.removeAll { $0.id == entry.id }
    }

    func clearAll() {
        storage.clearAll()
        entries.removeAll()
    }

    // MARK: - Keyboard navigation

    func selectNext() {
        let list = filteredEntries
        guard !list.isEmpty else { return }
        if let id = selectedID, let idx = list.firstIndex(where: { $0.id == id }) {
            selectedID = list[min(idx + 1, list.count - 1)].id
        } else {
            selectedID = list.first?.id
        }
    }

    func selectPrevious() {
        let list = filteredEntries
        guard !list.isEmpty else { return }
        if let id = selectedID, let idx = list.firstIndex(where: { $0.id == id }) {
            selectedID = list[max(idx - 1, 0)].id
        } else {
            selectedID = list.first?.id
        }
    }

    func pasteSelected() async {
        guard let id = selectedID,
              let entry = filteredEntries.first(where: { $0.id == id }) else { return }
        await paste(entry)
    }

    // MARK: - Cleanup

    private func scheduleCleanup() {
        Task {
            storage.deleteOlderThan(days: autoDeleteDays)
            storage.enforceLimit(maxItems)
            load()
        }

        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.storage.deleteOlderThan(days: self.autoDeleteDays)
                await self.monitor.start()
            }
        }
    }
}

private extension Int {
    func nonZero(default value: Int) -> Int { self == 0 ? value : self }
}
