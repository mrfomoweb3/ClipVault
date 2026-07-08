import SwiftData
import Foundation

@Model
final class ClipboardEntry {
    var id: UUID
    var content: String
    var contentType: ClipboardType
    var timestamp: Date
    var isPinned: Bool
    var appName: String?
    var preview: String

    // PNG bytes for image entries. Stored as an external file by SwiftData
    // so large images don't bloat the database. nil for non-image entries.
    @Attribute(.externalStorage) var imageData: Data?

    init(content: String,
         contentType: ClipboardType,
         appName: String? = nil,
         imageData: Data? = nil) {
        self.id = UUID()
        self.content = content
        self.contentType = contentType
        self.timestamp = Date()
        self.isPinned = false
        self.appName = appName
        self.preview = String(content.prefix(120))
        self.imageData = imageData
    }
}
