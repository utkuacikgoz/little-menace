import AppIntents
import Foundation
import WidgetKit
import MenaceCore

extension Notification.Name {
    /// Something outside the game model (a Siri or Shortcuts action in this process) wrote the save.
    static let lmSaveChangedElsewhere = Notification.Name("lm.saveChangedElsewhere")
}

/// Care given without the app on screen: a widget button or a Siri phrase. Same rules and points as in the app,
/// applied to the shared save, then the widgets redraw.
enum OffscreenCare {
    struct Result {
        let state: PetState
        let outcome: Outcome
        let line: String?
    }

    static func run(_ act: (inout Game, Date) -> Outcome) -> Result {
        let store = SharedStore.make()
        let now = Date()
        var game = Game(state: store.load(now: now).0)
        let outcome = act(&game, now)
        var rng = SystemRandomNumberGenerator()
        let line = Lines.next(for: outcome.refusal?.reaction ?? outcome.reaction, state: &game.state,
                              hour: game.days.hour(now), using: &rng)
        try? store.save(game.state)
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .lmSaveChangedElsewhere, object: nil)
        return Result(state: game.state, outcome: outcome, line: line)
    }

    /// How it's doing, in a sentence: for "How's my gremlin?" and the widgets.
    static func summary(_ s: PetState) -> String {
        if s.isAsleep { return "\(s.titleName) is asleep." }
        var wants: [String] = []
        if s.needs.fullness < 35 { wants.append("hungry") }
        if s.needs.joy < 40 { wants.append("bored") }
        if s.needs.energy < 30 { wants.append("sleepy") }
        let feeling: String
        switch s.mood {
        case .furious: feeling = "furious"
        case .angry: feeling = "angry"
        case .annoyed: feeling = "annoyed"
        case .calm: feeling = wants.isEmpty ? "content" : wants.joined(separator: " and ")
        }
        return "\(s.titleName) is \(feeling). Level \(s.level), \(s.points.total.formatted()) points."
    }
}

struct PetGremlinIntent: AppIntent {
    static let title: LocalizedStringResource = "Pet Your Gremlin"
    static let description = IntentDescription("Gives your gremlin a pet without opening the app.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let r = OffscreenCare.run { game, now in game.pet(now: now) }
        return .result(dialog: IntentDialog(stringLiteral: r.line ?? OffscreenCare.summary(r.state)))
    }
}

struct FeedGremlinIntent: AppIntent {
    static let title: LocalizedStringResource = "Feed Your Gremlin"
    static let description = IntentDescription("Gives your gremlin a snack without opening the app.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let r = OffscreenCare.run { game, now in game.feed(now: now) }
        return .result(dialog: IntentDialog(stringLiteral: r.line ?? OffscreenCare.summary(r.state)))
    }
}

struct GremlinStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Check On Your Gremlin"
    static let description = IntentDescription("Tells you how your gremlin is doing.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = SharedStore.make()
        var game = Game(state: store.load(now: Date()).0)
        _ = game.tick(now: Date())
        return .result(dialog: IntentDialog(stringLiteral: OffscreenCare.summary(game.state)))
    }
}
