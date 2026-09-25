import Foundation

/// Every gameplay number lives here so tuning is one file. All values are provisional.
public enum Tuning {
    // MARK: Time
    /// Absence beyond this is ignored: reopening after a week feels like reopening after 8 hours.
    public static let maxElapsed: TimeInterval = 8 * 3600

    // Per-hour rates.
    public static let fullnessDecayAwake = 8.0
    public static let fullnessDecayAsleep = 4.0
    public static let energyDecayAwake = 5.0
    public static let energyRecoveryAsleep = 240.0
    public static let joyDecay = 6.0

    /// Passing time alone never pushes needs below these. Play can, time cannot.
    public static let absenceFloor = Needs(fullness: 20, energy: 20, joy: 25)

    // MARK: Care
    public static let feedAmount = 25.0
    public static let feedJoy = 4.0
    public static let refuseFoodAt = 90.0
    public static let refuseNapAt = 75.0
    public static let tooSleepyToPlay = 15.0
    public static let maxNap: TimeInterval = 25 * 60
    /// Waking before this counts as an early (grumpy) wake. No penalty beyond the face.
    public static let restfulNap: TimeInterval = 5 * 60
    public static let petJoy = 2.0

    // MARK: Play
    public static let playEnergyCost = 6.0
    public static let playFullnessCost = 6.0
    public static let playJoy = 14.0

    // MARK: Progression
    public static let careXPPerDayCap = 20
    public static let feedXP = 2
    public static let petXP = 1
    public static let activityBaseXP = 8
    public static let activityBonusXP = 12
    public static let challengeXP = 30
    public static let discoveryXP = 15
    public static let stampMilestoneXP = 40
    public static let giftFallbackXP = 60
    public static let stampsForBonus = 3
    public static let stampsForGift = 5

    // MARK: Mischief
    public static let firstMischiefDelay: TimeInterval = 90
    public static let mischiefGapMin: TimeInterval = 3 * 3600
    public static let mischiefGapMax: TimeInterval = 5 * 3600
    public static let mischiefXP = 5

    // MARK: Offers
    /// The paid collection is only surfaced (inside the wardrobe) once the player has come back.
    public static let offerMinLevel = 3
    public static let offerMinVisitDays = 2

    /// XP required to reach `level` (level 1 needs 0).
    public static func xpForLevel(_ level: Int) -> Int {
        let n = max(0, level - 1)
        return 20 * n * (n + 1)
    }

    public static func level(forXP xp: Int) -> Int {
        var level = 1
        while xpForLevel(level + 1) <= xp { level += 1 }
        return level
    }
}
