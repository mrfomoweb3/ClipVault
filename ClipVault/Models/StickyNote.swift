import SwiftData
import SwiftUI

enum NoteColor: String, CaseIterable, Identifiable {
    case lemon, peach, mint, sky, lilac, rose

    var id: String { rawValue }

    var name: String {
        switch self {
        case .lemon: "Lemon"
        case .peach: "Peach"
        case .mint: "Mint"
        case .sky: "Sky"
        case .lilac: "Lilac"
        case .rose: "Rose"
        }
    }

    var paper: Color {
        switch self {
        case .lemon: Color(red: 1.00, green: 0.91, blue: 0.42)
        case .peach: Color(red: 1.00, green: 0.72, blue: 0.53)
        case .mint: Color(red: 0.67, green: 0.90, blue: 0.72)
        case .sky: Color(red: 0.62, green: 0.83, blue: 0.96)
        case .lilac: Color(red: 0.78, green: 0.70, blue: 0.95)
        case .rose: Color(red: 0.98, green: 0.68, blue: 0.75)
        }
    }
}

@Model
final class StickyNote {
    var id: UUID
    var text: String
    var colorName: String
    var createdAt: Date
    var updatedAt: Date
    var isVisible: Bool
    var windowX: Double?
    var windowY: Double?
    var windowWidth: Double
    var windowHeight: Double
    @Attribute(.externalStorage) var richTextData: Data?
    var widgetKey: String?

    init(text: String = "", color: NoteColor = .lemon, largeEditor: Bool = false) {
        id = UUID()
        self.text = text
        colorName = color.rawValue
        createdAt = Date()
        updatedAt = Date()
        isVisible = true
        windowX = nil
        windowY = nil
        windowWidth = largeEditor ? 560 : 360
        windowHeight = largeEditor ? 520 : 380
        richTextData = nil
        widgetKey = nil
    }

    var color: NoteColor {
        get { NoteColor(rawValue: colorName) ?? .lemon }
        set { colorName = newValue.rawValue }
    }
}
