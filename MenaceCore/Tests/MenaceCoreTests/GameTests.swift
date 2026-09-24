import XCTest
@testable import MenaceCore

final class GameTests: XCTestCase {
    let utc = DayClock(timeZone: TimeZone(identifier: "UTC")!)
    /// Monday 2026-09-21 10:00 UTC.
    let monday = ISO8601DateFormatter().date(from: "2026-09-21T10:00:00Z")!

    func makeGame(at date: Date? = nil) -> Game {
        var g = Game(state: PetState(now: date ?? monday), days: utc)
        _ = g.tick(now: date ?? monday)
        return g
    }

    func play(_ g: inout Game, _ kind: ActivityKind, quality: Double = 0.5, score: Int = 3, won: Bool = true, at now: Date) -> Outcome {
        guard case .success(let session) = g.startActivity(kind, now: now) else {
            XCTFail("could not start \(kind)")
            return Outcome(reaction: .busy, refusal: .busy, events: [])
        }
        return g.finishActivity(session, result: ActivityResult(kind: kind, quality: quality, score: score, won: won), now: now)
    }

    // MARK: Care thresholds

    func testFeedRefusedWhenFull() {
        var g = makeGame()
        g.state.needs.fullness = Tuning.refuseFoodAt
        XCTAssertEqual(g.feed(now: monday).refusal, .full)
        g.state.needs.fullness = 40
        let out = g.feed(now: monday)
        XCTAssertNil(out.refusal)
        XCTAssertEqual(g.state.needs.fullness, 40 + Tuning.feedAmount)
    }

    func testNapRefusedWhenRested() {
        var g = makeGame()
        g.state.needs.energy = 90
        XCTAssertEqual(g.sleep(now: monday).refusal, .notTired)
        g.state.needs.energy = 30
        XCTAssertNil(g.sleep(now: monday).refusal)
        XCTAssertEqual(g.feed(now: monday).refusal, .asleep)
        XCTAssertEqual(g.sleep(now: monday).refusal, .asleep)
        if case .failure(let r) = g.startActivity(.sockTug, now: monday) { XCTAssertEqual(r, .asleep) } else { XCTFail() }
    }

    func testEarlyWakeIsGrumpyButHarmless() {
        var g = makeGame()
        g.state.needs.energy = 30
        _ = g.sleep(now: monday)
        let out = g.wake(now: monday.addingTimeInterval(60))
        XCTAssertEqual(out.reaction, .grumpyWake)
        XCTAssertFalse(g.state.isAsleep)
        XCTAssertEqual(g.state.counters.naps, 0)
    }

    func testTooSleepyToPlay() {
        var g = makeGame()
        g.state.needs.energy = Tuning.tooSleepyToPlay - 1
        if case .failure(let r) = g.startActivity(.snackToss, now: monday) { XCTAssertEqual(r, .tooSleepy) } else { XCTFail() }
    }

    // MARK: Interrupted play

    func testConflictingActionsDuringPlayAreRefused() {
        var g = makeGame()
        g.state.needs.fullness = 40
        g.state.needs.energy = 50
        guard case .success = g.startActivity(.sockTug, now: monday) else { return XCTFail() }
        XCTAssertEqual(g.feed(now: monday).refusal, .busy)
        XCTAssertEqual(g.sleep(now: monday).refusal, .busy)
        if case .failure(let r) = g.startActivity(.snackToss, now: monday) { XCTAssertEqual(r, .busy) } else { XCTFail() }
    }

    func testCancelledRoundCostsAndGrantsNothing() {
        var g = makeGame()
        let before = g.state
        guard case .success = g.startActivity(.sockTug, now: monday) else { return XCTFail() }
        g.cancelActivity()
        XCTAssertNil(g.state.session)
        XCTAssertEqual(g.state.xp, before.xp)
        XCTAssertEqual(g.state.needs, before.needs)
        XCTAssertTrue(g.state.stamps.days.isEmpty)
    }

    func testFinishingTwiceRewardsOnce() {
        var g = makeGame()
        guard case .success(let session) = g.startActivity(.snackToss, now: monday) else { return XCTFail() }
        let result = ActivityResult(kind: .snackToss, quality: 1, score: 8, won: true)
        let first = g.finishActivity(session, result: result, now: monday)
        let xp = g.state.xp
        let second = g.finishActivity(session, result: result, now: monday)
        XCTAssertNil(first.refusal)
        XCTAssertEqual(second.refusal, .busy)
        XCTAssertEqual(g.state.xp, xp)
    }

    func testSessionIsNotPersisted() throws {
        var g = makeGame()
        guard case .success = g.startActivity(.cushionHunt, now: monday) else { return XCTFail() }
        let restored = try SaveCodec.decode(try SaveCodec.encode(g.state))
        XCTAssertNil(restored.session, "a relaunch never resumes a half-played round")
    }

    // MARK: Rewards granted once

    func testCareXPIsCappedPerDay() {
        var g = makeGame()
        for _ in 0..<100 { _ = g.pet(now: monday) }
        // Pet XP is capped; the only other XP possible is the pet challenge if it is today's.
        let challengeBonus = g.todaysChallenge == .petEight ? Tuning.challengeXP : 0
        XCTAssertEqual(g.state.xp, Tuning.careXPPerDayCap + challengeBonus)
        let tomorrow = monday.addingTimeInterval(86400)
        let out = g.pet(now: tomorrow)
        XCTAssertTrue(out.events.contains(.xp(Tuning.petXP)))
    }

    func testDailyChallengeGrantsOnceEvenAcrossTimeZoneRoundTrip() {
        let day = findDay(with: .winTug)
        var g = makeGame(at: day)
        var out = play(&g, .sockTug, won: true, at: day)
        XCTAssertTrue(out.events.contains(.challengeComplete(.winTug)))
        out = play(&g, .sockTug, won: true, at: day)
        XCTAssertFalse(out.events.contains(.challengeComplete(.winTug)))

        // Fly east (tomorrow locally), then back (today again): today stays paid.
        g.days = DayClock(timeZone: TimeZone(identifier: "Pacific/Kiritimati")!)
        _ = g.tick(now: day)
        g.days = utc
        _ = g.tick(now: day)
        XCTAssertTrue(g.state.challenge.completed)
        g.state.needs.energy = 100
        out = play(&g, .sockTug, won: true, at: day)
        XCTAssertFalse(out.events.contains(.challengeComplete(.winTug)))
        XCTAssertEqual(g.state.granted.filter { $0.hasPrefix("challenge:") }.count, 1)
    }

    func testCatchChallengeUsesBestSingleRound() {
        let day = findDay(with: .catchSix)
        var g = makeGame(at: day)
        var out = play(&g, .snackToss, quality: 0.5, score: 4, at: day)
        XCTAssertFalse(out.events.contains(.challengeComplete(.catchSix)))
        out = play(&g, .snackToss, quality: 0.8, score: 6, at: day)
        XCTAssertTrue(out.events.contains(.challengeComplete(.catchSix)))
        XCTAssertTrue(g.state.stamps.goldDays.contains(utc.dayKey(day)))
    }

    func testWeeklyStampsBonusAndGiftGrantOnce() {
        var g = makeGame()
        var gifts: [String] = []
        var bonuses = 0
        for d in 0..<7 {
            let now = monday.addingTimeInterval(Double(d) * 86400)
            for _ in 0..<2 {
                g.state.needs.energy = 100
                let out = play(&g, .cushionHunt, score: 2, won: true, at: now)
                bonuses += out.events.filter { $0 == .stampBonus }.count
                for case .weeklyGift(let id) in out.events { gifts.append(id) }
            }
        }
        XCTAssertEqual(g.state.stamps.days.count, 7)
        XCTAssertEqual(bonuses, 1)
        XCTAssertEqual(gifts.count, 1)
        XCTAssertTrue(g.state.wardrobe.earned.contains(gifts[0]))
        XCTAssertTrue(g.state.discoveries.contains(Discovery.fullCard.rawValue))

        // Next Monday: new card, a different gift.
        let next = monday.addingTimeInterval(7 * 86400)
        _ = g.tick(now: next)
        XCTAssertTrue(g.state.stamps.days.isEmpty)
        var nextGifts: [String] = []
        for d in 0..<5 {
            g.state.needs.energy = 100
            let out = play(&g, .cushionHunt, score: 2, at: next.addingTimeInterval(Double(d) * 86400))
            for case .weeklyGift(let id) in out.events { nextGifts.append(id) }
        }
        XCTAssertEqual(nextGifts.count, 1)
        XCTAssertNotEqual(nextGifts.first, gifts.first)
    }

    func testMissedDaysNeverRemoveStamps() {
        var g = makeGame()
        _ = play(&g, .cushionHunt, score: 2, at: monday)
        _ = g.tick(now: monday.addingTimeInterval(4 * 86400))
        XCTAssertEqual(g.state.stamps.days.count, 1)
    }

    func testDiscoveriesGrantOnce() {
        var g = makeGame()
        g.state.needs.fullness = 10
        let first = g.feed(now: monday)
        XCTAssertTrue(first.events.contains(.discovery(.firstBite)))
        let second = g.feed(now: monday)
        XCTAssertFalse(second.events.contains(.discovery(.firstBite)))
    }

    func testLevelUpAnnouncesUnlocks() {
        var g = makeGame()
        g.state.xp = Tuning.xpForLevel(2) - 1
        let out = play(&g, .cushionHunt, score: 3, won: false, at: monday)
        XCTAssertTrue(out.events.contains(.levelUp(2)))
        XCTAssertTrue(out.events.contains(.unlocked("leaf")))
    }

    // MARK: Mischief

    func testMischiefAppearsResolvesAndReschedules() {
        var g = makeGame()
        XCTAssertNil(g.pendingMischief(now: monday))
        let later = monday.addingTimeInterval(Tuning.firstMischiefDelay + 1)
        guard let event = g.pendingMischief(now: later) else { return XCTFail() }
        XCTAssertEqual(g.pendingMischief(now: later)?.id, event.id, "same event until resolved")
        let out = g.resolveMischief(event.id, indulge: true, now: later)
        XCTAssertNil(out.refusal)
        XCTAssertGreaterThan(g.state.personality, 0)
        XCTAssertNil(g.pendingMischief(now: later))
        XCTAssertEqual(g.resolveMischief(event.id, indulge: true, now: later).refusal, .busy)
        let gap = g.state.mischief.nextAt!.timeIntervalSince(later)
        XCTAssertGreaterThanOrEqual(gap, Tuning.mischiefGapMin)
        XCTAssertLessThanOrEqual(gap, Tuning.mischiefGapMax)
    }

    func testPersonalityStaysBounded() {
        var g = makeGame()
        var now = monday
        for _ in 0..<40 {
            now = g.state.mischief.nextAt!.addingTimeInterval(1)
            guard let e = g.pendingMischief(now: now) else { return XCTFail() }
            _ = g.resolveMischief(e.id, indulge: false, now: now)
        }
        XCTAssertEqual(g.state.personality, -1)
        XCTAssertTrue(g.state.discoveries.contains(Discovery.softie.rawValue))
    }

    // MARK: Helpers

    /// First day from `monday` whose deterministic challenge is `kind`.
    func findDay(with kind: ChallengeKind) -> Date {
        for d in 0..<365 {
            let date = monday.addingTimeInterval(Double(d) * 86400)
            if ChallengeKind.forDay(utc.dayKey(date)) == kind { return date }
        }
        XCTFail("no day for \(kind)")
        return monday
    }
}
