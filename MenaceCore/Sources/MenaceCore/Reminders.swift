import Foundation

public struct PlannedReminder: Equatable, Sendable {
    public var id: String
    public var date: Date
    public var body: String
}

/// Optional local reminders. Rules:
/// - Off until the player turns them on (the offer appears once, after a useful moment).
/// - At most one nudge per day, planned only a few days ahead and re-planned on every visit,
///   so an absent player gets a couple of friendly nudges and then silence. Never guilt.
/// - A nap in progress gets a single "awake" note at the expected wake time.
public enum ReminderPolicy {
    public static let daysAhead = 3

    static let nudges = [
        "Crumb found something shiny. Probably yours.",
        "Crumb is doing a tiny dance. Come see.",
        "The sock is ready for a rematch.",
        "Crumb saved you a snack. Mostly.",
        "Snack toss? Crumb is warming up.",
        "Crumb hid somewhere. Cushions look suspicious.",
    ]

    /// Show the soft offer after a moment that makes reminders useful (a nap, or a few rounds of play).
    public static func shouldOffer(_ s: PetState) -> Bool {
        guard !s.prefs.reminderOfferShown, !s.prefs.remindersEnabled else { return false }
        let rounds = s.counters.rounds.values.reduce(0, +)
        return s.isAsleep || rounds >= 3
    }

    public static func plan(_ s: PetState, now: Date, days: DayClock) -> [PlannedReminder] {
        guard s.prefs.remindersEnabled else { return [] }
        var out: [PlannedReminder] = []
        if let wake = TimeModel.expectedWake(s), wake > now {
            out.append(.init(id: "wake", date: wake, body: "Crumb is awake and suspiciously energetic."))
        }
        let cal = days.calendar
        let startOfToday = cal.startOfDay(for: now)
        // Today is skipped: the player is here right now.
        for offset in 1...daysAhead {
            guard let day = cal.date(byAdding: .day, value: offset, to: startOfToday),
                  let at = cal.date(bySettingHour: s.prefs.reminderHour, minute: s.prefs.reminderMinute, second: 0, of: day)
            else { continue }
            guard at > now else { continue }
            let key = days.dayKey(at)
            let body = nudges[Int(stableHash("nudge:" + key) % UInt64(nudges.count))]
            out.append(.init(id: "nudge-" + key, date: at, body: body))
        }
        return out
    }
}
