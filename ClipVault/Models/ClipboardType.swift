import Foundation

enum ClipboardType: String, Codable, CaseIterable {
    case text
    case url
    case code
    case filePath
    case image

    var icon: String {
        switch self {
        case .text:     return "doc.text"
        case .url:      return "link"
        case .code:     return "chevron.left.forwardslash.chevron.right"
        case .filePath: return "folder"
        case .image:    return "photo"
        }
    }

    var label: String {
        switch self {
        case .text:     return "Text"
        case .url:      return "URL"
        case .code:     return "Code"
        case .filePath: return "File"
        case .image:    return "Image"
        }
    }
}
