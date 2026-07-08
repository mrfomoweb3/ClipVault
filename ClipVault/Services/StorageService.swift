import SwiftData
import Foundation
import os

@MainActor
final class StorageService {
    private let logger = Logger(subsystem: "com.clipvault.app", category: "Storage")
    let container: ModelContainer

    init() throws {
        let schema = Schema([ClipboardEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try ModelContainer(for: schema, configurations: [config])
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
