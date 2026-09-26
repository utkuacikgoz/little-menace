import Foundation

/// Why points moved. Gains mirror the XP sources; losses come from neglect or pushing too hard.
public enum PointReason: String, Codable, CaseIterable, Sendable {
    // Gains
    case fed, petted, played, challenge, discovery, stampBonus, weeklyGift, mischief
    // Losses
    case hungry, wokeEarly, wornOut, forceFed, poked

    public var isPenalty: Bool {
        switch self {
        case .hungry, .wokeEarly, .wornOut, .forceFed, .poked: return true
        default: return false
        }
    }

    public var symbol: String {
        switch self {
        case .fed: return "fork.knife"
        case .petted: return "hand.raised.fill"
        case .played: return "tennisball.fill"
        case .challenge: return "checkmark.seal.fill"
        case .discovery: return "sparkle.magnifyingglass"
        case .stampBonus: return "seal.fill"
        case .weeklyGift: return "gift.fill"
        case .mischief: return "flame.fill"
        case .hungry: return "fork.knife.circle"
        case .wokeEarly: return "alarm.fill"
        case .wornOut: return "battery.0percent"
        case .forceFed: return "hand.raised.slash.fill"
        case .poked: return "hand.point.up.left.fill"
        }
    }

    /// How it works, for the rules list.
    public var rule: String {
        let careCap = "up to \(Tuning.careXPPerDayCap) a day from care"
        switch self {
        case .fed: return "+\(Tuning.feedXP) per snack, \(careCap)"
        case .petted: return "+\(Tuning.petXP) per pet, \(careCap)"
        case .played: return "+\(Tuning.activityBaseXP) to +\(Tuning.activityBaseXP + Tuning.activityBonusXP) per round"
        case .challenge: return "+\(Tuning.challengeXP) for today's challenge"
        case .discovery: return "+\(Tuning.discoveryXP) for each discovery"
        case .stampBonus: return "+\(Tuning.stampMilestoneXP) at \(Tuning.stampsForBonus) stamps in a week"
        case .weeklyGift: return "+\(Tuning.giftFallbackXP) when you already own every gift"
        case .mischief: return "+\(Tuning.mischiefXP) for dealing with mischief"
        case .hungry: return "−\(Tuning.hungryPenaltyPerHour) every hour it's over \(100 - Int(Tuning.hungryBelow))% hungry"
        case .wokeEarly: return "−\(Tuning.wokeEarlyPenalty) for waking it within \(Int(Tuning.restfulNap / 60)) minutes"
        case .wornOut: return "−\(Tuning.wornOutPenalty) per round played over \(100 - Int(Tuning.wornOutBelow))% sleepy"
        case .forceFed: return "−\(Tuning.forceFedPenalty) per snack pushed on a full belly"
        case .poked: return "−\(Tuning.pokePenalty) per pet after \(Tuning.pokesAllowed) in \(Int(Tuning.pokeWindow)) seconds"
        }
    }

    /// Short label for the history list.
    public var label: String {
        switch self {
        case .fed: return "Fed"
        case .petted: return "Petted"
        case .played: return "Played a round"
        case .challenge: return "Daily challenge"
        case .discovery: return "Discovery"
        case .stampBonus: return "Weekly stamp bonus"
        case .weeklyGift: return "Weekly gift"
        case .mischief: return "Handled mischief"
        case .hungry: return "Left hungry"
        case .wokeEarly: return "Woken too early"
        case .wornOut: return "Played while worn out"
        case .forceFed: return "Force-fed"
        case .poked: return "Poked too much"
        }
    }
}

/// One line of the points history. Repeats of the same reason on the same day merge into one line.
public struct PointsEntry: Codable, Equatable, Sendable, Identifiable {
    public var id: String { "\(day):\(reason.rawValue):\(at.timeIntervalSince1970)" }
    public var day: String
    public var at: Date
    public var reason: PointReason
    public var amount: Int
    public var count: Int

    public init(day: String, at: Date, reason: PointReason, amount: Int, count: Int = 1) {
        self.day = day
        self.at = at
        self.reason = reason
        self.amount = amount
        self.count = count
    }
}

public struct PointsBook: Codable, Equatable, Sendable {
    /// Never below zero.
    public var total = 0
    /// Newest last, capped at `Tuning.pointsHistoryLimit`.
    public var history: [PointsEntry] = []
    public var day = ""
    public var gainedToday = 0
    public var lostToday = 0
    /// Hours spent hungry that have not been charged yet (charged per whole hour).
    public var hungryHours = 0.0
    /// Rapid pets: start of the current burst and how many pets it holds.
    public var pokeBurstStart: Date?
    public var pokeBurst = 0

    public init() {}

    /// Applies `amount` (negative for a loss) and logs it. Returns the change actually applied.
    @discardableResult
    public mutating func apply(_ amount: Int, _ reason: PointReason, day today: String, at now: Date) -> Int {
        guard amount != 0 else { return 0 }
        if day != today {
            day = today
            gainedToday = 0
            lostToday = 0
        }
        var change = amount
        if change < 0 {
            // Losses are capped per day and never take the total below zero.
            change = -min(-change, Tuning.maxPointsLostPerDay - lostToday, total)
            guard change < 0 else { return 0 }
            lostToday -= change
        } else {
            gainedToday += change
        }
        total += change
        if var last = history.last, last.day == today, last.reason == reason {
            last.amount += change
            last.count += 1
            last.at = now
            history[history.count - 1] = last
        } else {
            history.append(PointsEntry(day: today, at: now, reason: reason, amount: change))
            if history.count > Tuning.pointsHistoryLimit { history.removeFirst(history.count - Tuning.pointsHistoryLimit) }
        }
        return change
    }
}
