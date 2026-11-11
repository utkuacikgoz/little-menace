import ActivityKit
import AppIntents
import Foundation
import MenaceCore

/// The nap on the Lock Screen and in the Dynamic Island: who is asleep, in what, and when it wakes up.
struct NapAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startedAt: Date
        var wakesAt: Date
    }

    var name: String
    var hat: String?
    var neck: String?
    var fur: String?
    var theme: String
}

/// Waking it from the Live Activity. Early, it wakes grumpy and costs points, exactly as in the app.
struct WakeGremlinIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Wake Your Gremlin"
    static let description = IntentDescription("Wakes your gremlin from its nap. Early, and it holds a grudge.")

    func perform() async throws -> some IntentResult {
        _ = OffscreenCare.run { game, now in game.wake(now: now) }
        for activity in Activity<NapAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}
