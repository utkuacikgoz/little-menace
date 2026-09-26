import Foundation

/// Local calendar keys. Always computed with the device's *current* time zone, so travelling
/// changes which day it is, and the grant ledger keeps any day from paying out twice.
public struct DayClock: Sendable {
    public var calendar: Calendar

    public init(timeZone: TimeZone = .current) {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = timeZone
        calendar = cal
    }

    public func dayKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public func weekKey(_ date: Date) -> String {
        let c = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", c.yearForWeekOfYear ?? 0, c.weekOfYear ?? 0)
    }

    /// Monday-first index 0...6 of `date` within its ISO week.
    public func weekdayIndex(_ date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date) // 1 = Sunday
        return (weekday + 5) % 7
    }

    public func hour(_ date: Date) -> Int { calendar.component(.hour, from: date) }
}

public enum TimeModel {
    /// Advances needs from `state.lastSimulated` to `now`.
    ///
    /// Rules:
    /// - Elapsed time is capped at `Tuning.maxElapsed`.
    /// - A clock set backwards costs nothing: the anchor moves back to `now` and no time passes.
    /// - Passing time never drops a need below the absence floor (or lower than it already was).
    /// - A nap ends on its own when energy is full or the nap hits `Tuning.maxNap`.
    /// Returns true if the pet woke up on its own during this advance.
    @discardableResult
    public static func advance(_ s: inout PetState, to now: Date) -> Bool {
        let raw = now.timeIntervalSince(s.lastSimulated)
        s.lastSimulated = now
        if let start = s.napStartedAt, start > now { s.napStartedAt = now }
        guard raw > 0 else { return false }
        let hours = min(raw, Tuning.maxElapsed) / 3600

        let floor = Tuning.absenceFloor
        func decay(_ value: Double, by amount: Double, floor: Double) -> Double {
            max(value - amount, min(value, floor))
        }

        if let start = s.napStartedAt {
            s.needs.energy = min(100, s.needs.energy + Tuning.energyRecoveryAsleep * hours)
            s.needs.fullness = decay(s.needs.fullness, by: Tuning.fullnessDecayAsleep * hours, floor: floor.fullness)
            let napLength = now.timeIntervalSince(start)
            if s.needs.energy >= 100 || napLength >= Tuning.maxNap {
                s.napStartedAt = nil
                s.pendingWake = true
                s.needs.clamp()
                return true
            }
        } else {
            s.needs.fullness = decay(s.needs.fullness, by: Tuning.fullnessDecayAwake * hours, floor: floor.fullness)
            s.needs.energy = decay(s.needs.energy, by: Tuning.energyDecayAwake * hours, floor: floor.energy)
            s.needs.joy = decay(s.needs.joy, by: Tuning.joyDecay * hours, floor: floor.joy)
        }
        s.needs.clamp()
        return false
    }

    /// Hours out of the next `hours` that a need starting at `start` and falling at `rate` per hour
    /// spends below `threshold`. Passing time stops at `floor`, so a floor at or above the
    /// threshold means time alone never gets there.
    public static func hoursBelow(_ threshold: Double, start: Double, rate: Double, floor: Double, hours: Double) -> Double {
        guard hours > 0 else { return 0 }
        if start < threshold { return hours }
        guard rate > 0, floor < threshold else { return 0 }
        return max(0, hours - (start - threshold) / rate)
    }

    /// When a nap in progress is expected to end on its own, for the optional wake notification.
    public static func expectedWake(_ s: PetState) -> Date? {
        guard let start = s.napStartedAt else { return nil }
        let toFull = max(0, 100 - s.needs.energy) / Tuning.energyRecoveryAsleep * 3600
        return min(s.lastSimulated.addingTimeInterval(toFull), start.addingTimeInterval(Tuning.maxNap))
    }
}

/// Small deterministic hash (FNV-1a). Swift's `hashValue` is randomised per launch, so it
/// cannot pick "today's challenge" consistently.
public func stableHash(_ s: String) -> UInt64 {
    var h: UInt64 = 0xcbf29ce484222325
    for b in s.utf8 {
        h ^= UInt64(b)
        h = h &* 0x100000001b3
    }
    return h
}

/// Seedable generator so tests and the share card are reproducible.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed }
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
