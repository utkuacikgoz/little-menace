import ActivityKit
import SwiftUI
import WidgetKit
import MenaceCore

@main
struct LittleMenaceWidgets: WidgetBundle {
    var body: some Widget {
        GremlinWidget()
        NapLiveActivityWidget()
    }
}

// MARK: Home Screen and Lock Screen

struct GremlinEntry: TimelineEntry {
    let date: Date
    let state: PetState
}

/// Reads the shared save and plans the next few hours: needs drop as time passes, so the face changes too.
struct GremlinProvider: TimelineProvider {
    func placeholder(in context: Context) -> GremlinEntry {
        GremlinEntry(date: Date(), state: PetState(now: Date()))
    }

    func getSnapshot(in context: Context, completion: @escaping (GremlinEntry) -> Void) {
        completion(entries(from: Date(), count: 1).first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GremlinEntry>) -> Void) {
        completion(Timeline(entries: entries(from: Date(), count: 13), policy: .atEnd))
    }

    /// Every 30 minutes for six hours.
    private func entries(from start: Date, count: Int) -> [GremlinEntry] {
        var game = Game(state: SharedStore.make().load(now: start).0)
        return (0..<count).map { i in
            let date = start.addingTimeInterval(Double(i) * 30 * 60)
            _ = game.tick(now: date)
            return GremlinEntry(date: date, state: game.state)
        }
    }
}

struct GremlinWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Gremlin", provider: GremlinProvider()) { entry in
            GremlinEntryView(entry: entry)
        }
        .configurationDisplayName("Your gremlin")
        .description("See how it's doing, and pet or feed it right from here.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private struct GremlinEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: GremlinEntry

    var body: some View {
        GremlinWidgetView(family: family, state: entry.state)
            .containerBackground(for: .widget) {
                if family == .systemSmall || family == .systemMedium { GremlinWidgetBackground(state: entry.state) }
            }
    }
}

// MARK: Nap Live Activity

struct NapLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NapAttributes.self) { context in
            NapBanner(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color(hex: 0x241F33))
                .activitySystemActionForegroundColor(Color(hex: 0xFFF7EA))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    NapBanner(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                NapIslandLeading()
            } compactTrailing: {
                NapIslandTrailing(state: context.state)
            } minimal: {
                NapIslandLeading()
            }
        }
    }
}
