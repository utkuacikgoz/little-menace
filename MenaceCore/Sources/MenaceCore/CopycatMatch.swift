import Foundation

public enum DanceMove: Int, CaseIterable, Sendable {
    case up, down, left, right
}

/// Copycat Dance rules. The gremlin dances a short routine; the player copies it move by move.
/// Each routine copied adds one move. The first mistake ends the round. Pure, so it is testable.
public struct CopycatMatch: Sendable {
    public static let startLength = 3
    /// Copy a routine this long and the round counts as a win.
    public static let winLength = 5
    /// Copy a routine this long and the round ends in a perfect win.
    public static let maxLength = 12

    public enum Step: Equatable, Sendable {
        /// Right move, routine not finished yet.
        case correct
        /// Whole routine copied; it is now one move longer.
        case routineDone
        case mistake
        case finished
    }

    public private(set) var routine: [DanceMove] = []
    /// Moves copied so far in the current routine.
    public private(set) var copied = 0
    /// Length of the longest routine copied in full.
    public private(set) var best = 0
    public private(set) var outcome: Bool?
    private var rng: SplitMix64

    public init(seed: UInt64) {
        rng = SplitMix64(seed: seed)
        for _ in 0..<Self.startLength { addMove() }
    }

    private mutating func addMove() {
        var move = DanceMove.allCases.randomElement(using: &rng)!
        // Never the same move three times running: it reads as a stutter, not a dance.
        if routine.count >= 2, routine.suffix(2).allSatisfy({ $0 == move }) {
            move = DanceMove(rawValue: (move.rawValue + 1) % DanceMove.allCases.count)!
        }
        routine.append(move)
    }

    @discardableResult
    public mutating func input(_ move: DanceMove) -> Step {
        guard outcome == nil else { return .finished }
        guard move == routine[copied] else {
            outcome = best >= Self.winLength
            return .mistake
        }
        copied += 1
        guard copied == routine.count else { return .correct }
        best = routine.count
        copied = 0
        if best >= Self.maxLength {
            outcome = true
            return .finished
        }
        addMove()
        return .routineDone
    }

    public var result: ActivityResult {
        let won = outcome ?? (best >= Self.winLength)
        return ActivityResult(kind: .copycat, quality: min(1, Double(best) / 8), score: best, won: won)
    }
}
