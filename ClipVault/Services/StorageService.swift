import SwiftData
import Foundation
import os

@MainActor
final class StorageService {
    private let logger = Logger(subsystem: "com.clipvault.app", category: "Storage")
    let container: ModelContainer

    init() throws {
        let schema = Schema([ClipboardEntry.self])

        // Use an explicit, app-namespaced store URL. The SwiftData default is
        // `~/Library/Application Support/default.store`, which — for a
        // non-sandboxed app — is SHARED with every other non-sandboxed app that
        // also uses the default name (e.g. iCloud Mail). That collision made
        // ClipVault's store fail to open on some launches (notably at login),
        // so capturing silently stopped after a restart. A dedicated path fixes it.
        let dir = URL.applicationSupportDirectory.appending(path: "ClipVault", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let storeURL = dir.appending(path: "ClipVault.store")

        do {
            let config = ModelConfiguration(schema: schema, url: storeURL)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Never brick the app over storage — fall back to in-memory so the
            // clipboard still works this session (history just won't persist).
            logger.error("On-disk store failed (\(error.localizedDescription)); using in-memory store")
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try ModelContainer(for: schema, configurations: [mem])
        }
    }

    var context: ModelContext { container.mainContext }

    func save(_ entry: ClipboardEntry) {
        context.insert(entry)
        do {
            try context.save()
        } catch {
            logger.error("Save failed: \(error.localizedDescription)")
        }
    }

    func delete(_ entry: ClipboardEntry) {
        context.delete(entry)
        do {
            try context.save()
        } catch {
            logger.error("Delete failed: \(error.localizedDescription)")
        }
    }

    func fetchAll(limit: Int = 200) -> [ClipboardEntry] {
        var descriptor = FetchDescriptor<ClipboardEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        do {
            let results = try context.fetch(descriptor)
            // Sort pinned items to the top in-memory
            return results.sorted { a, b in
                if a.isPinned != b.isPinned { return a.isPinned }
                return a.timestamp > b.timestamp
            }
        } catch {
            logger.error("Fetch failed: \(error.localizedDescription)")
            return []
        }
    }

    func clearAll() {
        do {
            try context.delete(model: ClipboardEntry.self)
            try context.save()
        } catch {
            logger.error("Clear all failed: \(error.localizedDescription)")
        }
    }

    func deleteOlderThan(days: Int) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = #Predicate<ClipboardEntry> { entry in
            entry.timestamp < cutoff && entry.isPinned == false
        }
        var descriptor = FetchDescriptor<ClipboardEntry>(predicate: predicate)
        descriptor.fetchLimit = 500
        do {
            let stale = try context.fetch(descriptor)
            stale.forEach { context.delete($0) }
            try context.save()
        } catch {
            logger.error("Delete old failed: \(error.localizedDescription)")
        }
    }

    func enforceLimit(_ max: Int) {
        let descriptor = FetchDescriptor<ClipboardEntry>(
            predicate: #Predicate { $0.isPinned == false },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        do {
            let all = try context.fetch(descriptor)
            if all.count > max {
                all.dropFirst(max).forEach { context.delete($0) }
                try context.save()
            }
        } catch {
            logger.error("Enforce limit failed: \(error.localizedDescription)")
        }
    }
}
