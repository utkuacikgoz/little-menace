import XCTest
@testable import MenaceCore

final class TugMatchTests: XCTestCase {
    func run(_ m: inout TugMatch, fps: Double = 60, pull: (TugMatch) -> Double) {
        var guardSteps = 0
        while m.outcome == nil && guardSteps < 10_000 {
            m.step(dt: 1 / fps, pull: pull(m))
            guardSteps += 1
        }
    }

    func testNotPullingLoses() {
        var m = TugMatch(seed: 1)
        run(&m) { _ in 0 }
        XCTAssertEqual(m.outcome, false)
    }

    func testPullingOnlyWhenTiredWins() {
        var m = TugMatch(seed: 1)
        run(&m) { $0.gremlinTired ? 1 : 0.3 }
        XCTAssertEqual(m.outcome, true)
        XCTAssertGreaterThan(m.windowsUsed, 0)
        XCTAssertTrue(m.result.won)
    }

    func testYankingNonstopLoses() {
        var smart = TugMatch(seed: 3)
        run(&smart) { $0.gremlinTired ? 1 : 0.2 }
        var brute = TugMatch(seed: 3)
        run(&brute) { _ in 1 }
        XCTAssertEqual(smart.outcome, true)
        // Yanking nonstop makes the sock slip: timing is what the game rewards.
        XCTAssertEqual(brute.outcome, false)
    }

    func testFrameRateIndependent() {
        var a = TugMatch(seed: 9)
        var b = TugMatch(seed: 9)
        run(&a, fps: 120) { $0.gremlinTired ? 1 : 0.4 }
        run(&b, fps: 20) { $0.gremlinTired ? 1 : 0.4 }
        XCTAssertEqual(a.outcome, b.outcome)
    }

    func testCancelledGestureMeansNoPullAndNoStuckState() {
        var m = TugMatch(seed: 4)
        m.step(dt: 0.5, pull: 1)
        m.step(dt: 0.5, pull: 1)
        m.step(dt: 0.5, pull: 1) // past warmup, rope moved
        let rope = m.rope
        m.step(dt: 0.1, pull: 0) // gesture cancelled: GestureState resets pull to 0
        XCTAssertLessThanOrEqual(m.rope, rope)
    }

    func testHitchesAreClamped() {
        var m = TugMatch(seed: 5)
        m.step(dt: 30, pull: 0) // app hitch or long pause: at most 0.5 s simulated
        XCTAssertLessThanOrEqual(m.elapsed, 0.5 + 1e-9)
    }

    func testFinishedMatchIgnoresFurtherSteps() {
        var m = TugMatch(seed: 1)
        run(&m) { _ in 0 }
        let snapshot = (m.rope, m.elapsed)
        m.step(dt: 0.5, pull: 1)
        XCTAssertEqual(m.rope, snapshot.0)
        XCTAssertEqual(m.elapsed, snapshot.1)
    }
}
