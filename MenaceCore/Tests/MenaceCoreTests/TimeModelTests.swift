import XCTest
@testable import MenaceCore

final class TimeModelTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_790_000_000) // fixed, avoids wall-clock flakiness
    let utc = DayClock(timeZone: TimeZone(identifier: "UTC")!)

    func testDecayIsLinearWithinCap() {
        var s = PetState(now: t0)
        s.needs = Needs(fullness: 80, energy: 80, joy: 80)
        TimeModel.advance(&s, to: t0.addingTimeInterval(3600))
        XCTAssertEqual(s.needs.fullness, 80 - Tuning.fullnessDecayAwake, accuracy: 0.001)
        XCTAssertEqual(s.needs.energy, 80 - Tuning.energyDecayAwake, accuracy: 0.001)
        XCTAssertEqual(s.needs.joy, 80 - Tuning.joyDecay, accuracy: 0.001)
    }

    func testLongAbsenceIsCappedAndFloored() {
        var week = PetState(now: t0)
        week.needs = Needs(fullness: 100, energy: 100, joy: 100)
        var cap = week
        TimeModel.advance(&week, to: t0.addingTimeInterval(7 * 86400))
        TimeModel.advance(&cap, to: t0.addingTimeInterval(Tuning.maxElapsed))
        XCTAssertEqual(week.needs, cap.needs, "a week away equals the cap")

        var low = PetState(now: t0)
        low.needs = Needs(fullness: 30, energy: 30, joy: 30)
        TimeModel.advance(&low, to: t0.addingTimeInterval(7 * 86400))
        XCTAssertEqual(low.needs.fullness, Tuning.absenceFloor.fullness)
        XCTAssertEqual(low.needs.energy, Tuning.absenceFloor.energy)
        XCTAssertEqual(low.needs.joy, Tuning.absenceFloor.joy)
    }

    func testAbsenceNeverRaisesAValueAlreadyBelowFloor() {
        var s = PetState(now: t0)
        s.needs = Needs(fullness: 5, energy: 5, joy: 5)
        TimeModel.advance(&s, to: t0.addingTimeInterval(3600))
        XCTAssertEqual(s.needs, Needs(fullness: 5, energy: 5, joy: 5))
    }

    func testClockMovedBackwardsCostsNothingAndRebases() {
        var s = PetState(now: t0)
        let before = s.needs
        TimeModel.advance(&s, to: t0.addingTimeInterval(-3 * 3600))
        XCTAssertEqual(s.needs, before)
        XCTAssertEqual(s.lastSimulated, t0.addingTimeInterval(-3 * 3600))
    }

    func testNapInFutureAfterClockChangeIsPulledBack() {
        var s = PetState(now: t0)
        s.napStartedAt = t0
        TimeModel.advance(&s, to: t0.addingTimeInterval(-600))
        XCTAssertEqual(s.napStartedAt, t0.addingTimeInterval(-600))
    }

    func testNapRecoversAndEndsOnItsOwn() {
        var s = PetState(now: t0)
        s.needs.energy = 20
        s.napStartedAt = t0
        XCTAssertFalse(TimeModel.advance(&s, to: t0.addingTimeInterval(5 * 60)))
        XCTAssertTrue(s.isAsleep)
        XCTAssertEqual(s.needs.energy, 40, accuracy: 0.001)
        XCTAssertTrue(TimeModel.advance(&s, to: t0.addingTimeInterval(20 * 60)))
        XCTAssertFalse(s.isAsleep)
        XCTAssertTrue(s.pendingWake)
        XCTAssertEqual(s.needs.energy, 100)
    }

    func testExpectedWakeRespectsMaxNap() {
        var s = PetState(now: t0)
        s.needs.energy = 0
        s.napStartedAt = t0
        let wake = TimeModel.expectedWake(s)!
        XCTAssertLessThanOrEqual(wake, t0.addingTimeInterval(Tuning.maxNap))
    }

    func testDayAndWeekKeysFollowTimeZone() {
        // 2026-09-27 23:30 UTC is Sunday in UTC and Monday in Tokyo.
        let date = ISO8601DateFormatter().date(from: "2026-09-27T23:30:00Z")!
        let tokyo = DayClock(timeZone: TimeZone(identifier: "Asia/Tokyo")!)
        XCTAssertEqual(utc.dayKey(date), "2026-09-27")
        XCTAssertEqual(tokyo.dayKey(date), "2026-09-28")
        XCTAssertEqual(utc.weekKey(date), "2026-W39")
        XCTAssertEqual(tokyo.weekKey(date), "2026-W40")
        XCTAssertEqual(utc.weekdayIndex(date), 6)
        XCTAssertEqual(tokyo.weekdayIndex(date), 0)
    }

    func testStableHashIsStable() {
        XCTAssertEqual(stableHash("crumb"), stableHash("crumb"))
        XCTAssertEqual(ChallengeKind.forDay("2026-09-24"), ChallengeKind.forDay("2026-09-24"))
    }
}
