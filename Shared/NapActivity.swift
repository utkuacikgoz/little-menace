import ActivityKit
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
