import Foundation

public struct PlannedReminder: Equatable, Sendable {
    public var id: String
    public var date: Date
    public var body: String
}

/// Optional local reminders. Rules:
/// - Off until the player turns them on (the offer appears after a useful moment, and once more a few days later).
/// - At most one nudge per day, planned only a few days ahead and re-planned on every visit,
///   so an absent player gets a couple of friendly nudges and then silence. Never guilt.
/// - A nap in progress gets a single "awake" note at the expected wake time.
public enum ReminderPolicy {
    public static let daysAhead = 3
    /// A skipped offer comes back once, this long after it was first shown.
    public static let offerAgainAfter: TimeInterval = 3 * 86400
    /// A mischief note only between these hours, and only if it is at least an hour away.
    static let mischiefHours = 9..<21

    static let nudges = [
        "{name} found something shiny. Probably yours.",
        "{name} is doing a tiny dance. Come see.",
        "The sock is ready for a rematch.",
        "{name} saved you a snack. Mostly.",
        "Snack toss? {name} is warming up.",
        "{name} hid somewhere. Cushions look suspicious.",
    ]

    /// Show the soft offer after a moment that makes reminders useful (a nap, or a few rounds of play):
    /// the first time, and once more a few days after it was skipped.
    public static func shouldOffer(_ s: PetState, now: Date) -> Bool {
        guard !s.prefs.remindersEnabled else { return false }
        if s.prefs.reminderOfferShown {
            // Players who saw it before the second chance existed get theirs at the next useful moment.
            guard (s.prefs.reminderOfferAgainAt ?? .distantPast) <= now else { return false }
        }
        let rounds = s.counters.rounds.values.reduce(0, +)
        return s.isAsleep || rounds >= 3
    }

    /// Records that the offer was shown: the first time schedules the second chance, the second ends it.
    public static func markOffered(_ s: inout PetState, now: Date) {
        s.prefs.reminderOfferAgainAt = s.prefs.reminderOfferShown ? .distantFuture : now.addingTimeInterval(offerAgainAfter)
        s.prefs.reminderOfferShown = true
    }

    public static func plan(_ s: PetState, now: Date, days: DayClock) -> [PlannedReminder] {
        guard s.prefs.remindersEnabled else { return [] }
        var out: [PlannedReminder] = []
        if let wake = TimeModel.expectedWake(s), wake > now {
            out.append(.init(id: "wake", date: wake, body: "\(s.titleName) is awake and suspiciously energetic."))
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
            let body = stampNudge(s, on: at, days: days)
                ?? nudges[Int(stableHash("nudge:" + key) % UInt64(nudges.count))].replacingOccurrences(of: "{name}", with: s.titleName)
            out.append(.init(id: "nudge-" + key, date: at, body: body))
        }
        // Mischief ready while the player is away: that day's one note says so instead.
        if let at = s.mischief.nextAt, at >= now.addingTimeInterval(3600), mischiefHours.contains(days.hour(at)), !s.isAsleep,
           at <= cal.date(byAdding: .day, value: daysAhead + 1, to: startOfToday) ?? at {
            let key = days.dayKey(at)
            out.removeAll { $0.id == "nudge-" + key }
            out.append(.init(id: "mischief", date: at, body: "\(s.titleName) is up to something. Come see."))
        }
        return out.sorted { $0.date < $1.date }
    }

    /// On the last day of the week, when one more stamp unlocks a reward.
    static func stampNudge(_ s: PetState, on date: Date, days: DayClock) -> String? {
        guard days.weekdayIndex(date) == 6, s.stamps.weekKey == days.weekKey(date),
              !s.stamps.days.contains(days.dayKey(date)) else { return nil }
        switch s.stamps.days.count {
        case 4: return "One more stamp and \(s.titleName)'s weekly gift is yours. Last day!"
        case 2: return "One more stamp gets this week's bonus. Last day!"
        default: return nil
        }
    }
}

/// When to ask "How's your gremlin?": on the first launch of each new app version, for players who
/// have had it at least a day (a new player is never asked on day one). Happy answers get Apple's
/// rating prompt, which Apple caps at three times a year; the others go to the feedback email.
public enum ReviewPolicy {
    public static let minAge: TimeInterval = 86400

    public static func shouldAskOnLaunch(_ s: PetState, now: Date, appVersion: String) -> Bool {
        now.timeIntervalSince(s.createdAt) >= minAge && s.prefs.reviewAskedVersion != appVersion
    }
}
