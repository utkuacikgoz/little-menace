import Foundation

/// What Crumb does in response. Drives the animation rig and the (rare) speech line.
public enum Reaction: String, CaseIterable, Sendable {
    case idle, attention, touch, feed, play, sleepy, asleep, wake, grumpyWake, mischief
    case refuseFood, refuseNap, tooSleepy, busy, win, lose, levelUp, discovery
}

public enum Refusal: Error, Equatable, Sendable {
    case asleep, full, notTired, tooSleepy, busy, awake

    public var reaction: Reaction {
        switch self {
        case .asleep: return .asleep
        case .full: return .refuseFood
        case .notTired: return .refuseNap
        case .tooSleepy: return .tooSleepy
        case .busy: return .busy
        case .awake: return .idle
        }
    }
}

public struct Outcome: Equatable, Sendable {
    public var reaction: Reaction
    public var refusal: Refusal?
    public var events: [GameEvent]

    static func refused(_ r: Refusal) -> Outcome { Outcome(reaction: r.reaction, refusal: r, events: []) }
}

/// The rules engine. Pure value type; the app owns one, saves `state`, and passes `now` in.
public struct Game: Sendable {
    public var state: PetState
    public var days: DayClock

    public init(state: PetState, days: DayClock = DayClock()) {
        self.state = state
        self.days = days
    }

    // MARK: Time

    /// Call on launch, on foreground, and periodically while open.
    public mutating func tick(now: Date) -> [GameEvent] {
        var events: [GameEvent] = []
        if TimeModel.advance(&state, to: now) {
            state.counters.naps += 1
            events.append(.autoWoke)
            progressChallenge(.restfulNap, by: 1, now: now, events: &events)
            discover(.firstNap, events: &events)
        }
        let today = days.dayKey(now)
        if state.counters.lastVisitDay != today {
            state.counters.lastVisitDay = today
            state.counters.visitDays += 1
            if state.counters.visitDays >= 5 { discover(.regular, events: &events) }
        }
        rollOver(now: now)
        return events
    }

    private mutating func rollOver(now: Date) {
        let today = days.dayKey(now)
        if state.challenge.dayKey != today {
            state.challenge = ChallengeProgress()
            state.challenge.dayKey = today
            // A challenge already paid today (e.g. after a time zone round-trip) stays done.
            state.challenge.completed = state.granted.contains("challenge:" + today)
        }
        let week = days.weekKey(now)
        if state.stamps.weekKey != week {
            state.stamps = StampCard()
            state.stamps.weekKey = week
        }
        if state.counters.playedDay != today {
            state.counters.playedDay = today
            state.counters.playedKinds = []
        }
    }

    public var todaysChallenge: ChallengeKind { ChallengeKind.forDay(state.challenge.dayKey) }

    // MARK: Care

    public mutating func feed(now: Date) -> Outcome {
        var events = tick(now: now)
        if state.isAsleep { return .refused(.asleep) }
        if state.session != nil { return .refused(.busy) }
        if state.needs.fullness >= Tuning.refuseFoodAt { return .refused(.full) }
        state.needs.fullness += Tuning.feedAmount
        state.needs.joy += Tuning.feedJoy
        state.needs.clamp()
        state.counters.feeds += 1
        careXP(Tuning.feedXP, now: now, events: &events)
        discover(.firstBite, events: &events)
        return Outcome(reaction: .feed, refusal: nil, events: events)
    }

    public mutating func pet(now: Date) -> Outcome {
        var events = tick(now: now)
        if state.isAsleep { return Outcome(reaction: .asleep, refusal: nil, events: events) }
        state.needs.joy = min(100, state.needs.joy + Tuning.petJoy)
        state.counters.pets += 1
        careXP(Tuning.petXP, now: now, events: &events)
        progressChallenge(.petEight, by: 1, now: now, events: &events)
        return Outcome(reaction: .touch, refusal: nil, events: events)
    }

    public mutating func sleep(now: Date) -> Outcome {
        let events = tick(now: now)
        if state.isAsleep { return .refused(.asleep) }
        if state.session != nil { return .refused(.busy) }
        if state.needs.energy >= Tuning.refuseNapAt { return .refused(.notTired) }
        state.napStartedAt = now
        state.pendingWake = false
        return Outcome(reaction: .asleep, refusal: nil, events: events)
    }

    public mutating func wake(now: Date) -> Outcome {
        var events = tick(now: now)
        guard let start = state.napStartedAt else { return .refused(.awake) }
        state.napStartedAt = nil
        let restful = now.timeIntervalSince(start) >= Tuning.restfulNap
        if restful {
            state.counters.naps += 1
            progressChallenge(.restfulNap, by: 1, now: now, events: &events)
            discover(.firstNap, events: &events)
        }
        return Outcome(reaction: restful ? .wake : .grumpyWake, refusal: nil, events: events)
    }

    /// Clears the "woke while you were away" flag once the app has shown the wake.
    public mutating func acknowledgeWake() { state.pendingWake = false }

    // MARK: Play

    public mutating func startActivity(_ kind: ActivityKind, now: Date) -> Result<ActivitySession, Refusal> {
        _ = tick(now: now)
        if state.isAsleep { return .failure(.asleep) }
        if state.session != nil { return .failure(.busy) }
        if state.needs.energy < Tuning.tooSleepyToPlay { return .failure(.tooSleepy) }
        let session = ActivitySession(id: UUID(), kind: kind, startedAt: now)
        state.session = session
        return .success(session)
    }

    /// Interrupted or abandoned rounds cost nothing and grant nothing.
    public mutating func cancelActivity() { state.session = nil }

    public mutating func finishActivity(_ session: ActivitySession, result: ActivityResult, now: Date) -> Outcome {
        guard state.session?.id == session.id, result.kind == session.kind else {
            return .refused(.busy) // stale or duplicated finish: never rewards twice
        }
        state.session = nil
        var events = tick(now: now)

        state.needs.energy -= Tuning.playEnergyCost
        state.needs.fullness -= Tuning.playFullnessCost
        state.needs.joy += Tuning.playJoy * (0.5 + 0.5 * result.quality)
        state.needs.clamp()

        let key = session.kind.rawValue
        state.counters.rounds[key, default: 0] += 1
        if result.won { state.counters.wins[key, default: 0] += 1 }
        if !state.counters.playedKinds.contains(key) { state.counters.playedKinds.append(key) }

        addXP(Tuning.activityBaseXP + Int((Double(Tuning.activityBonusXP) * result.quality).rounded()), events: &events)
        stampToday(gold: false, now: now, events: &events)

        switch session.kind {
        case .snackToss:
            progressChallenge(.catchSix, toAtLeast: result.score, now: now, events: &events)
            if result.quality >= 1 { discover(.perfectToss, events: &events) }
        case .sockTug:
            if result.won {
                progressChallenge(.winTug, by: 1, now: now, events: &events)
                discover(.firstTugWin, events: &events)
            }
        case .cushionHunt:
            if result.won && result.score == 1 {
                progressChallenge(.firstTryFind, by: 1, now: now, events: &events)
                discover(.firstTryFind, events: &events)
            }
        }
        progressChallenge(.playAllThree, toAtLeast: state.counters.playedKinds.count, now: now, events: &events)
        let hour = days.hour(now)
        if hour < 4 { discover(.nightOwl, events: &events) }

        return Outcome(reaction: result.won ? .win : .lose, refusal: nil, events: events)
    }

    // MARK: Mischief

    public func pendingMischief(now: Date) -> MischiefEvent? {
        guard !state.isAsleep, state.session == nil, let at = state.mischief.nextAt, at <= now else { return nil }
        return MischiefBook.next(after: state.mischief.recent, seed: String(Int(at.timeIntervalSince1970)))
    }

    public mutating func resolveMischief(_ id: String, indulge: Bool, now: Date) -> Outcome {
        var events = tick(now: now)
        guard let event = pendingMischief(now: now), event.id == id else { return .refused(.busy) }
        let choice = indulge ? event.indulge : event.redirect
        state.personality = min(1, max(-1, state.personality + choice.personality))
        state.needs.joy += choice.joy
        state.needs.fullness += choice.fullness
        state.needs.clamp()
        state.counters.mischiefResolved += 1
        state.mischief.recent = Array((state.mischief.recent + [id]).suffix(8))
        state.mischief.nextAt = now.addingTimeInterval(MischiefBook.gap(seed: "\(id):\(state.counters.mischiefResolved)"))
        addXP(Tuning.mischiefXP, events: &events)
        if state.personality >= 0.6 { discover(.menace, events: &events) }
        if state.personality <= -0.6 { discover(.softie, events: &events) }
        return Outcome(reaction: indulge ? .mischief : .touch, refusal: nil, events: events)
    }

    // MARK: Rewards (each guarded by the grant ledger)

    private mutating func grantOnce(_ key: String) -> Bool {
        state.granted.insert(key).inserted
    }

    private mutating func addXP(_ amount: Int, events: inout [GameEvent]) {
        guard amount > 0 else { return }
        let before = state.level
        state.xp += amount
        events.append(.xp(amount))
        let after = state.level
        guard after > before else { return }
        for level in (before + 1)...after {
            events.append(.levelUp(level))
            for item in Catalog.unlocks(atLevel: level) { events.append(.unlocked(item.id)) }
        }
    }

    private mutating func careXP(_ amount: Int, now: Date, events: inout [GameEvent]) {
        let today = days.dayKey(now)
        if state.counters.careXPDay != today {
            state.counters.careXPDay = today
            state.counters.careXP = 0
        }
        let allowed = min(amount, Tuning.careXPPerDayCap - state.counters.careXP)
        guard allowed > 0 else { return }
        state.counters.careXP += allowed
        addXP(allowed, events: &events)
    }

    private mutating func discover(_ d: Discovery, events: inout [GameEvent]) {
        guard state.discoveries.insert(d.rawValue).inserted else { return }
        events.append(.discovery(d))
        addXP(Tuning.discoveryXP, events: &events)
    }

    private mutating func progressChallenge(_ kind: ChallengeKind, by amount: Int, now: Date, events: inout [GameEvent]) {
        progressChallenge(kind, toAtLeast: nil, adding: amount, now: now, events: &events)
    }

    private mutating func progressChallenge(_ kind: ChallengeKind, toAtLeast value: Int, now: Date, events: inout [GameEvent]) {
        progressChallenge(kind, toAtLeast: value, adding: 0, now: now, events: &events)
    }

    private mutating func progressChallenge(_ kind: ChallengeKind, toAtLeast value: Int?, adding: Int, now: Date, events: inout [GameEvent]) {
        rollOver(now: now)
        let today = state.challenge.dayKey
        guard ChallengeKind.forDay(today) == kind, !state.challenge.completed else { return }
        state.challenge.progress = max(state.challenge.progress + adding, value ?? 0)
        guard state.challenge.progress >= kind.target else { return }
        state.challenge.completed = true
        guard grantOnce("challenge:" + today) else { return }
        events.append(.challengeComplete(kind))
        addXP(Tuning.challengeXP, events: &events)
        stampToday(gold: true, now: now, events: &events)
    }

    private mutating func stampToday(gold: Bool, now: Date, events: inout [GameEvent]) {
        rollOver(now: now)
        let today = days.dayKey(now)
        var card = state.stamps
        var changed = false
        if !card.days.contains(today) {
            card.days.append(today)
            changed = true
        }
        if gold && !card.goldDays.contains(today) {
            card.goldDays.append(today)
            changed = true
        }
        state.stamps = card
        guard changed else { return }
        events.append(.stamp(gold: gold))

        let week = card.weekKey
        let count = card.days.count
        if count >= Tuning.stampsForBonus, grantOnce("week:\(week):bonus") {
            events.append(.stampBonus)
            addXP(Tuning.stampMilestoneXP, events: &events)
        }
        if count >= Tuning.stampsForGift, grantOnce("week:\(week):gift") {
            let rotation = Catalog.weeklyGiftRotation
            let start = Int(stableHash(week) % UInt64(rotation.count))
            let order = rotation[start...] + rotation[..<start]
            if let gift = order.first(where: { !state.wardrobe.earned.contains($0) }) {
                state.wardrobe.earned.insert(gift)
                events.append(.weeklyGift(gift))
            } else {
                addXP(Tuning.giftFallbackXP, events: &events)
            }
        }
        if count >= 7 { discover(.fullCard, events: &events) }
    }

    // MARK: Reset

    public mutating func reset(now: Date) {
        let prefs = state.prefs
        state = PetState(now: now)
        state.prefs.sound = prefs.sound
        state.prefs.haptics = prefs.haptics
        _ = tick(now: now)
    }
}
