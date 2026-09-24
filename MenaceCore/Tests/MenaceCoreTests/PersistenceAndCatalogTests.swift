import XCTest
@testable import MenaceCore

final class PersistenceTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_790_000_000)
    var dir: URL!

    override func setUp() {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: dir)
    }

    func testRoundTrip() throws {
        var s = PetState(now: t0)
        s.xp = 321
        s.napStartedAt = t0
        s.discoveries = ["firstBite"]
        s.wardrobe.hat = "leaf"
        s.granted = ["challenge:2026-09-24"]
        s.counters.rounds["sockTug"] = 4
        let back = try SaveCodec.decode(try SaveCodec.encode(s))
        XCTAssertEqual(back, s)
    }

    func testMissingFieldsFallBackToDefaults() throws {
        let json = #"{"version":1,"state":{"lastSimulated":1790000000,"xp":50}}"#
        let s = try SaveCodec.decode(Data(json.utf8))
        XCTAssertEqual(s.xp, 50)
        XCTAssertEqual(s.name, "")
        XCTAssertEqual(s.displayName, "your gremlin")
        XCTAssertEqual(s.wardrobe.theme, Catalog.defaultTheme)
    }

    func testOutOfRangeValuesAreClamped() throws {
        let json = #"{"version":1,"state":{"lastSimulated":1790000000,"xp":-5,"personality":9,"needs":{"fullness":500,"energy":-3,"joy":50}}}"#
        let s = try SaveCodec.decode(Data(json.utf8))
        XCTAssertEqual(s.xp, 0)
        XCTAssertEqual(s.personality, 1)
        XCTAssertEqual(s.needs, Needs(fullness: 100, energy: 0, joy: 50))
    }

    func testMigrationStepsRunInOrder() throws {
        // A hypothetical v1 → v2 → v3 chain, exercised with an injected table.
        let v1 = #"{"version":1,"state":{"lastSimulated":1790000000,"points":12}}"#
        let table: [Int: SaveCodec.Migration] = [
            1: { s in s["xp"] = s.removeValue(forKey: "points") },
            2: { s in s["xp"] = (s["xp"] as? Int ?? 0) * 10 },
        ]
        let s = try SaveCodec.decode(Data(v1.utf8), current: 3, migrations: table)
        XCTAssertEqual(s.xp, 120)
        XCTAssertThrowsError(try SaveCodec.decode(Data(v1.utf8), current: 3, migrations: [:])) {
            XCTAssertEqual($0 as? SaveCodec.Failure, .missingMigration(1))
        }
    }

    func testFutureVersionIsRejected() {
        let json = #"{"version":99,"state":{"lastSimulated":1790000000}}"#
        XCTAssertThrowsError(try SaveCodec.decode(Data(json.utf8))) {
            XCTAssertEqual($0 as? SaveCodec.Failure, .futureVersion(99))
        }
    }

    func testStoreRecoversFromCorruptPrimaryUsingBackup() throws {
        let store = SaveStore(directory: dir)
        var s = PetState(now: t0)
        s.xp = 10
        try store.save(s)
        s.xp = 20
        try store.save(s) // backup now holds xp 10
        try Data("{garbage".utf8).write(to: store.primary)

        let (loaded, source) = store.load(now: t0)
        XCTAssertEqual(source, .backup)
        XCTAssertEqual(loaded.xp, 10)
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertTrue(files.contains { $0.hasPrefix("pet.bad.") }, "corrupt save is kept aside, not deleted")
    }

    func testStoreStartsFreshWhenNothingReadable() {
        let store = SaveStore(directory: dir)
        let (s, source) = store.load(now: t0)
        XCTAssertEqual(source, .fresh)
        XCTAssertEqual(s.lastSimulated, t0)
    }

    func testResetKeepsSoundPrefsOnly() {
        var g = Game(state: PetState(now: t0), days: DayClock(timeZone: TimeZone(identifier: "UTC")!))
        g.state.xp = 999
        g.state.prefs.sound = false
        g.state.prefs.remindersEnabled = true
        g.reset(now: t0)
        XCTAssertEqual(g.state.xp, 0)
        XCTAssertFalse(g.state.prefs.sound)
        XCTAssertFalse(g.state.prefs.remindersEnabled)
    }
}

final class CatalogTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_790_000_000)
    let pid = Catalog.midnightProductID

    func testEntitlementsIgnoreRevokedAndUnknown() {
        let owned = Entitlements.owned(from: [
            TransactionRecord(productID: pid, revoked: false),
            TransactionRecord(productID: "unknown.product", revoked: false),
        ])
        XCTAssertEqual(owned, [pid])
        XCTAssertEqual(Entitlements.owned(from: [TransactionRecord(productID: pid, revoked: true)]), [])
    }

    func testRevocationUnequipsPaidItems() {
        var s = PetState(now: t0)
        s.wardrobe.hat = "nightcap"
        s.wardrobe.theme = "midnight"
        s.wardrobe.sock = "glow"
        XCTAssertFalse(Catalog.sanitize(&s, entitlements: [pid]))
        XCTAssertTrue(Catalog.sanitize(&s, entitlements: []))
        XCTAssertNil(s.wardrobe.hat)
        XCTAssertEqual(s.wardrobe.theme, Catalog.defaultTheme)
        XCTAssertEqual(s.wardrobe.sock, Catalog.defaultSock)
    }

    func testLevelItemsOwnedByLevel() {
        var s = PetState(now: t0)
        let leaf = Catalog.item("leaf")!
        XCTAssertFalse(Catalog.isOwned(leaf, state: s, entitlements: []))
        s.xp = Tuning.xpForLevel(2)
        XCTAssertTrue(Catalog.isOwned(leaf, state: s, entitlements: []))
    }

    func testOfferWaitsForAttachment() {
        var s = PetState(now: t0)
        XCTAssertFalse(OfferPolicy.canShowOffer(s))
        s.xp = Tuning.xpForLevel(Tuning.offerMinLevel)
        XCTAssertFalse(OfferPolicy.canShowOffer(s), "a level alone on day one is not enough")
        s.counters.visitDays = Tuning.offerMinVisitDays
        XCTAssertTrue(OfferPolicy.canShowOffer(s))
    }

    func testCatalogIntegrity() {
        XCTAssertEqual(Set(Catalog.items.map(\.id)).count, Catalog.items.count)
        for c in Catalog.collections {
            for id in c.itemIDs { XCTAssertEqual(Catalog.item(id)?.source, .collection(c.id)) }
        }
        for id in Catalog.weeklyGiftRotation { XCTAssertEqual(Catalog.item(id)?.source, .weeklyGift) }
        XCTAssertEqual(Set(MischiefBook.events.map(\.id)).count, MischiefBook.events.count)
    }

    func testLinesAreShort() {
        for line in Lines.allLines { XCTAssertLessThanOrEqual(line.count, 32, line) }
        var rng = SplitMix64(seed: 1)
        for r in Reaction.allCases where r != .idle {
            _ = Lines.line(for: r, personality: 0, using: &rng)
        }
    }
}

final class ReminderTests: XCTestCase {
    let utc = DayClock(timeZone: TimeZone(identifier: "UTC")!)
    let now = ISO8601DateFormatter().date(from: "2026-09-21T10:00:00Z")!

    func testNothingPlannedUnlessEnabled() {
        XCTAssertTrue(ReminderPolicy.plan(PetState(now: now), now: now, days: utc).isEmpty)
    }

    func testAtMostOnePerDayAndStopsAfterAFewDays() {
        var s = PetState(now: now)
        s.prefs.remindersEnabled = true
        let plan = ReminderPolicy.plan(s, now: now, days: utc)
        XCTAssertEqual(plan.count, ReminderPolicy.daysAhead)
        XCTAssertEqual(Set(plan.map { utc.dayKey($0.date) }).count, plan.count)
        XCTAssertFalse(plan.contains { utc.dayKey($0.date) == utc.dayKey(now) }, "never nudges on a day already visited")
        XCTAssertTrue(plan.allSatisfy { $0.date > now })
    }

    func testNudgesUseTheChosenName() {
        var s = PetState(now: now)
        s.prefs.remindersEnabled = true
        XCTAssertTrue(ReminderPolicy.plan(s, now: now, days: utc).allSatisfy { !$0.body.contains("{name}") })
        s.rename("Mo")
        let bodies = ReminderPolicy.plan(s, now: now, days: utc).map(\.body)
        XCTAssertTrue(bodies.contains { $0.contains("Mo") })
    }

    func testRenameCleansInput() {
        var s = PetState(now: now)
        s.rename("  Sir Nibbles the Unstoppable\n ")
        XCTAssertEqual(s.name, String("Sir Nibbles the Unstoppable".prefix(PetState.maxNameLength)))
        s.rename("   ")
        XCTAssertEqual(s.titleName, "Your gremlin")
        let back = try! SaveCodec.decode(try! SaveCodec.encode({ var t = s; t.rename("Mo"); return t }()))
        XCTAssertEqual(back.name, "Mo")
    }

    func testNapAddsWakeNote() {
        var s = PetState(now: now)
        s.prefs.remindersEnabled = true
        s.needs.energy = 40
        s.napStartedAt = now
        let plan = ReminderPolicy.plan(s, now: now, days: utc)
        XCTAssertEqual(plan.first?.id, "wake")
    }

    func testOfferAppearsOnceAfterUsefulMoment() {
        var s = PetState(now: now)
        XCTAssertFalse(ReminderPolicy.shouldOffer(s))
        s.counters.rounds = ["sockTug": 3]
        XCTAssertTrue(ReminderPolicy.shouldOffer(s))
        s.prefs.reminderOfferShown = true
        XCTAssertFalse(ReminderPolicy.shouldOffer(s))
    }
}
