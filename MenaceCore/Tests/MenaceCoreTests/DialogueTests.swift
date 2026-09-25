import XCTest
@testable import MenaceCore

final class DialogueTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_790_000_000)

    func testAuthoredLibraryHasAtLeast300UniqueShortLines() {
        XCTAssertGreaterThanOrEqual(Set(Lines.allLines).count, 300)
        XCTAssertEqual(Set(Lines.allLines).count, Lines.allLines.count)
        for line in Lines.allLines { XCTAssertLessThanOrEqual(line.count, 32, line) }
    }

    func testSmallPoolExhaustsBeforeRepeatingEvenAcrossSaves() throws {
        var state = PetState(now: now)
        var rng = SplitMix64(seed: 15)
        let count = Lines.table[.refuseFood]!.count
        var spoken: [String] = []
        for _ in 0..<count {
            spoken.append(try XCTUnwrap(Lines.next(for: .refuseFood, state: &state, hour: 12, using: &rng)))
            state = try SaveCodec.decode(SaveCodec.encode(state))
        }
        XCTAssertEqual(Set(spoken).count, count)
        XCTAssertEqual(Lines.next(for: .refuseFood, state: &state, hour: 12, using: &rng), spoken.first)
    }

    func testLargePoolAvoidsLast50AndBoundsSaveSize() {
        var state = PetState(now: now)
        state.counters.rounds = ["sockTug": 1, "snackToss": 1, "cushionHunt": 1]
        state.counters.visitDays = 4
        state.wardrobe.hat = "leaf"
        var rng = SplitMix64(seed: 87)
        for _ in 0..<300 {
            let previous = state.recentLines
            let line = Lines.next(for: .idle, state: &state, hour: 22, using: &rng)!
            XCTAssertFalse(previous.contains(line))
            XCTAssertLessThanOrEqual(state.recentLines.count, 50)
        }
    }

    func testSleepAndHungerTakePrecedenceOverIdleJokes() {
        var state = PetState(now: now)
        state.napStartedAt = now
        state.needs.fullness = 20
        XCTAssertEqual(Lines.pool(for: .idle, state: state, hour: 9), Lines.table[.asleep])
        state.napStartedAt = nil
        XCTAssertEqual(Lines.pool(for: .idle, state: state, hour: 9), Lines.contexts["hungry"])
        state.needs.energy = 10
        XCTAssertEqual(Lines.pool(for: .idle, state: state, hour: 9), Lines.table[.sleepy])
    }

    func testRemembersOnlyThingsThePlayerActuallyDid() {
        var state = PetState(now: now)
        let memory = Lines.contexts["tugMemory"]!
        XCTAssertTrue(Set(Lines.pool(for: .idle, state: state, hour: 12)).isDisjoint(with: memory))
        state.counters.rounds["sockTug"] = 1
        XCTAssertTrue(Set(memory).isSubset(of: Lines.pool(for: .idle, state: state, hour: 12)))
    }

    func testOldSavesHaveEmptyDialogueHistory() throws {
        let old = #"{"version":1,"state":{"lastSimulated":1790000000,"name":"Mo"}}"#
        let state = try SaveCodec.decode(Data(old.utf8))
        XCTAssertEqual(state.name, "Mo")
        XCTAssertTrue(state.recentLines.isEmpty)
    }
}
