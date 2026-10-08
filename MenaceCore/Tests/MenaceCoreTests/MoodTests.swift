import XCTest
@testable import MenaceCore

final class MoodTests: XCTestCase {
    let utc = DayClock(timeZone: TimeZone(identifier: "UTC")!)
    let monday = ISO8601DateFormatter().date(from: "2026-09-21T10:00:00Z")!

    func makeGame() -> Game {
        var g = Game(state: PetState(now: monday), days: utc)
        _ = g.tick(now: monday)
        return g
    }

    func earlyWake(_ g: inout Game, at t: Date) {
        g.state.needs.energy = 30
        g.state.noNapUntil = nil
        _ = g.sleep(now: t)
        _ = g.wake(now: t.addingTimeInterval(10))
    }

    // MARK: Temper

    func testLostPointsBuildTemperUpToFurious() {
        var g = makeGame()
        XCTAssertEqual(g.state.mood, .calm)
        earlyWake(&g, at: monday)
        XCTAssertEqual(g.state.temper, Double(Tuning.wokeEarlyPenalty), accuracy: 0.1)
        for i in 1..<9 { earlyWake(&g, at: monday.addingTimeInterval(Double(i * 20))) }
        XCTAssertEqual(g.state.mood, .furious)
        for i in 0..<20 { earlyWake(&g, at: monday.addingTimeInterval(Double(200 + i * 20))) }
        XCTAssertEqual(g.state.temper, Tuning.temperMax, "temper is capped")
    }

    func testFuriousRefusesToPlayUntilCalmed() {
        var g = makeGame()
        g.state.temper = Tuning.temperMax
        let t = monday.addingTimeInterval(1)
        guard case .failure(let r) = g.startActivity(.snackToss, now: t) else { return XCTFail("should refuse") }
        XCTAssertEqual(r, .furious)
        XCTAssertEqual(r.reaction, .furious)
        for _ in 0..<2 { _ = g.pet(now: t) }
        XCTAssertLessThan(g.state.temper, Tuning.furiousAt, "a pet calms it")
        guard case .success = g.startActivity(.snackToss, now: t) else { return XCTFail("calmed, should play") }
    }

    func testTemperCoolsWithTimeAndGains() {
        var g = makeGame()
        g.state.temper = 30
        _ = g.tick(now: monday.addingTimeInterval(3600))
        XCTAssertEqual(g.state.temper, 30 - Tuning.temperCoolPerHour, accuracy: 0.01)
        g.state.discoveries.insert(Discovery.firstBite.rawValue)
        g.state.needs.fullness = 40
        _ = g.feed(now: monday.addingTimeInterval(3600))
        XCTAssertEqual(g.state.temper, 30 - Tuning.temperCoolPerHour - Double(Tuning.feedXP), accuracy: 0.01)
        g.state.temper = 5
        _ = g.tick(now: monday.addingTimeInterval(2 * 3600))
        XCTAssertEqual(g.state.temper, 0, "never below calm")
    }

    func testMoodThresholds() {
        XCTAssertEqual(Mood(temper: 0), .calm)
        XCTAssertEqual(Mood(temper: Tuning.annoyedAt), .annoyed)
        XCTAssertEqual(Mood(temper: Tuning.angryAt), .angry)
        XCTAssertEqual(Mood(temper: Tuning.furiousAt), .furious)
    }

    // MARK: Puke

    func testThirdForceFeedInARowPukes() {
        var g = makeGame()
        g.state.needs.fullness = 95
        g.state.needs.joy = 50
        XCTAssertEqual(g.feed(now: monday).reaction, .refuseFood)
        XCTAssertEqual(g.feed(now: monday.addingTimeInterval(30)).reaction, .refuseFood)
        let out = g.feed(now: monday.addingTimeInterval(60))
        XCTAssertEqual(out.reaction, .puke)
        XCTAssertNil(out.refusal)
        XCTAssertTrue(g.state.mess)
        XCTAssertEqual(g.state.needs.fullness, Tuning.fullnessAfterPuke, accuracy: 0.5)
        XCTAssertLessThan(g.state.needs.joy, 50)
        XCTAssertEqual(g.state.forceFeeds, 0)
        XCTAssertTrue(out.events.contains(.points(-Tuning.forceFedPenalty, .forceFed)), "the third shove still costs")
    }

    func testSpacedOutForceFeedsDoNotPuke() {
        var g = makeGame()
        for i in 0..<4 {
            g.state.needs.fullness = 95
            XCTAssertEqual(g.feed(now: monday.addingTimeInterval(Double(i) * (Tuning.pukeWindow + 1))).reaction, .refuseFood)
        }
        XCTAssertFalse(g.state.mess)
    }

    func testCleaningTheMessPaysOnce() {
        var g = makeGame()
        g.state.mess = true
        let before = g.state.points.total
        let out = g.cleanMess(now: monday)
        XCTAssertFalse(g.state.mess)
        XCTAssertEqual(g.state.points.total, before + Tuning.cleanXP)
        XCTAssertTrue(out.events.contains(.points(Tuning.cleanXP, .cleaned)))
        _ = g.cleanMess(now: monday)
        XCTAssertEqual(g.state.points.total, before + Tuning.cleanXP, "no mess, no reward")
    }

    // MARK: Spite

    func testGrumpyWakeRefusesNapsForAWhile() {
        var g = makeGame()
        earlyWake(&g, at: monday)
        g.state.needs.energy = 30
        let soon = monday.addingTimeInterval(60)
        let out = g.sleep(now: soon)
        XCTAssertEqual(out.refusal, .spite)
        XCTAssertEqual(out.reaction, .spite)
        XCTAssertTrue(out.events.isEmpty, "spite costs nothing")
        let later = monday.addingTimeInterval(10 + Tuning.spiteNoNap + 1)
        g.state.needs.energy = 30
        XCTAssertNil(g.sleep(now: later).refusal)
    }

    func testRestfulWakeIsNotSpiteful() {
        var g = makeGame()
        g.state.needs.energy = 30
        _ = g.sleep(now: monday)
        _ = g.wake(now: monday.addingTimeInterval(Tuning.restfulNap))
        XCTAssertNil(g.state.noNapUntil)
    }

    // MARK: Saves

    func testMoodFieldsRoundTripAndOldSavesLoad() throws {
        var s = PetState(now: monday)
        s.temper = 33
        s.mess = true
        s.forceFeeds = 2
        s.lastForceFeed = monday
        s.noNapUntil = monday
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(PetState.self, from: data)
        XCTAssertEqual(back.temper, 33)
        XCTAssertTrue(back.mess)
        XCTAssertEqual(back.forceFeeds, 2)
        XCTAssertEqual(back.noNapUntil, monday)

        var json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        for k in ["temper", "mess", "forceFeeds", "lastForceFeed", "noNapUntil"] { json.removeValue(forKey: k) }
        let old = try JSONDecoder().decode(PetState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(old.temper, 0)
        XCTAssertFalse(old.mess)
        XCTAssertNil(old.noNapUntil)
    }

    // MARK: Copycat

    func testCopyingRoutinesGrowsThemAndAMistakeEndsTheRound() {
        var m = CopycatMatch(seed: 7)
        XCTAssertEqual(m.routine.count, CopycatMatch.startLength)
        for _ in 0..<3 {
            let routine = m.routine
            for (i, move) in routine.enumerated() {
                XCTAssertEqual(m.input(move), i == routine.count - 1 ? .routineDone : .correct)
            }
        }
        XCTAssertEqual(m.best, 5)
        XCTAssertEqual(m.routine.count, 6)
        let wrong = DanceMove(rawValue: (m.routine[0].rawValue + 1) % 4)!
        XCTAssertEqual(m.input(wrong), .mistake)
        XCTAssertEqual(m.outcome, true, "five copied is a win")
        XCTAssertEqual(m.input(.up), .finished)
        XCTAssertEqual(m.result.kind, .copycat)
        XCTAssertEqual(m.result.score, 5)
        XCTAssertTrue(m.result.won)
    }

    func testEarlyMistakeLoses() {
        var m = CopycatMatch(seed: 1)
        let wrong = DanceMove(rawValue: (m.routine[0].rawValue + 1) % 4)!
        m.input(wrong)
        XCTAssertEqual(m.outcome, false)
        XCTAssertFalse(m.result.won)
        XCTAssertEqual(m.result.quality, 0)
    }

    func testPerfectRunEndsAtMaxLength() {
        var m = CopycatMatch(seed: 99)
        var steps = 0
        while m.outcome == nil && steps < 500 {
            m.input(m.routine[m.copied])
            steps += 1
        }
        XCTAssertEqual(m.outcome, true)
        XCTAssertEqual(m.best, CopycatMatch.maxLength)
        XCTAssertEqual(m.result.quality, 1)
    }

    func testRoutinesNeverRepeatAMoveThreeTimes() {
        for seed in 0..<50 {
            var m = CopycatMatch(seed: UInt64(seed))
            while m.outcome == nil { m.input(m.routine[m.copied]) }
            for i in 2..<m.routine.count {
                XCTAssertFalse(m.routine[i] == m.routine[i - 1] && m.routine[i] == m.routine[i - 2])
            }
        }
    }

    func testCopycatRoundCountsAsPlay() {
        var g = makeGame()
        guard case .success(let s) = g.startActivity(.copycat, now: monday) else { return XCTFail() }
        let out = g.finishActivity(s, result: ActivityResult(kind: .copycat, quality: 0.6, score: 5, won: true), now: monday)
        XCTAssertEqual(out.reaction, .win)
        XCTAssertEqual(g.state.counters.rounds(.copycat), 1)
    }
}
