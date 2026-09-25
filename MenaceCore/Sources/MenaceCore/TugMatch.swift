import Foundation

/// Sock tug rules. The gremlin alternates strong pulls with short tired windows; pulling during
/// a tired window is what wins. Pure and stepped by the view each frame, so it is testable
/// and a cancelled gesture (pull 0) can never leave the rope stuck.
public struct TugMatch: Sendable {
    public static let warmup = 1.2
    public static let duration = 20.0
    static let gremlinStrong = 0.3
    static let gremlinTired = 0.05
    static let playerInStrong = 0.15
    /// Yanking while the gremlin pulls strong makes the sock slip (quadratic, so light tension is fine).
    static let slip = 0.35
    static let playerInTired = 1.1
    static let tiredLength = 0.75

    /// −1 the gremlin has the sock … +1 the player has it.
    public private(set) var rope = 0.0
    public private(set) var elapsed = 0.0
    public private(set) var outcome: Bool?
    /// Tired windows in which the player actually pulled.
    public private(set) var windowsUsed = 0
    private var windows: [ClosedRange<Double>] = []
    private var usedCurrent = false

    public init(seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        var t = Self.warmup
        while t < Self.duration {
            t += Double.random(in: 1.3...2.3, using: &rng)
            windows.append(t...(t + Self.tiredLength))
            t += Self.tiredLength
        }
    }

    public var isWarmingUp: Bool { elapsed < Self.warmup }
    public var gremlinTired: Bool { windows.contains { $0.contains(elapsed) } }
    public var timeLeft: Double { max(0, Self.duration - elapsed) }

    /// `pull` is 0…1 (drag depth). Large dt (a hitch) is split so outcomes do not depend on frame rate.
    public mutating func step(dt: Double, pull: Double) {
        guard outcome == nil else { return }
        var remaining = max(0, min(dt, 0.5))
        while remaining > 0, outcome == nil {
            let h = min(remaining, 1.0 / 60)
            remaining -= h
            advance(h, pull: max(0, min(1, pull)))
        }
    }

    private mutating func advance(_ h: Double, pull: Double) {
        let wasTired = gremlinTired
        elapsed += h
        if isWarmingUp { return }
        let tired = gremlinTired
        if tired != wasTired { usedCurrent = false }
        let gremlin = tired ? Self.gremlinTired : Self.gremlinStrong
        let player = tired ? pull * Self.playerInTired : pull * Self.playerInStrong - pull * pull * Self.slip
        if tired && pull > 0.3 && !usedCurrent {
            usedCurrent = true
            windowsUsed += 1
        }
        rope = max(-1, min(1, rope + (player - gremlin) * h))
        if rope >= 1 { outcome = true }
        else if rope <= -1 { outcome = false }
        else if elapsed >= Self.duration { outcome = rope > 0 }
    }

    public var result: ActivityResult {
        let won = outcome ?? false
        let quality = won ? max(0.6, 1 - elapsed / (Self.duration * 1.5)) : 0.25
        return ActivityResult(kind: .sockTug, quality: quality, score: windowsUsed, won: won)
    }
}
