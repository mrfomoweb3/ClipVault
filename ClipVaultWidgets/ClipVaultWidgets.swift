import WidgetKit
import SwiftUI
import AppIntents

@main
struct ClipVaultWidgetBundle: WidgetBundle {
    var body: some Widget {
        StickyNoteWidget()
    }
}

struct StickyNoteWidget: Widget {
    let kind = "ClipVaultStickyNote"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: StickyNoteConfiguration.self,
            provider: StickyNoteProvider()
        ) { entry in
            StickyNoteWidgetView(entry: entry)
                .containerBackground(entry.paperColor, for: .widget)
        }
        .configurationDisplayName("Sticky Note")
        .description("Right-click the widget and choose Edit Sticky Note to change its text or color.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct StickyNoteEntry: TimelineEntry {
    let date: Date
    let configuration: StickyNoteConfiguration

    var plainText: String { configuration.noteText }
    var paperColor: Color { configuration.paperColor }
}

struct StickyNoteProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StickyNoteEntry {
        StickyNoteEntry(date: .now, configuration: .preview)
    }

    func snapshot(for configuration: StickyNoteConfiguration, in context: Context) async -> StickyNoteEntry {
        StickyNoteEntry(date: .now, configuration: configuration)
    }

    func timeline(for configuration: StickyNoteConfiguration, in context: Context) async -> Timeline<StickyNoteEntry> {
        Timeline(entries: [StickyNoteEntry(date: .now, configuration: configuration)], policy: .never)
    }
}

struct StickyNoteWidgetView: View {
    let entry: StickyNoteEntry

    var body: some View {
        ZStack(alignment: .topLeading) {
            entry.paperColor

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Circle()
                        .fill(.black.opacity(0.32))
                        .frame(width: 6, height: 6)
                    Spacer()
                    Text("CLIPVAULT")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.black.opacity(0.62))
                }

                noteText
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, 14)

                HStack(spacing: 5) {
                    Image(systemName: "note.text")
                    Text("Sticky Note")
                }
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private var noteText: some View {
        Text(entry.plainText.isEmpty ? "Right-click to edit this note." : entry.plainText)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(.black.opacity(entry.plainText.isEmpty ? 0.45 : 0.82))
    }
}

struct StickyNoteConfiguration: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Sticky Note"
    static let description = IntentDescription("Choose the text and paper color for this desktop widget.")

    @Parameter(title: "Note", default: "A small thought worth keeping.")
    var noteText: String

    @Parameter(title: "Paper color", default: .lemon)
    var paperColorChoice: WidgetPaperColor

    var paperColor: Color { paperColorChoice.color }

    static var preview: StickyNoteConfiguration {
        let value = StickyNoteConfiguration()
        value.noteText = "A small thought worth keeping."
        value.paperColorChoice = .lemon
        return value
    }
}

enum WidgetPaperColor: String, AppEnum {
    case lemon, peach, mint, sky, lilac, rose

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Paper color")
    static let caseDisplayRepresentations: [WidgetPaperColor: DisplayRepresentation] = [
        .lemon: "Lemon",
        .peach: "Peach",
        .mint: "Mint",
        .sky: "Sky",
        .lilac: "Lilac",
        .rose: "Rose"
    ]

    var color: Color {
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
