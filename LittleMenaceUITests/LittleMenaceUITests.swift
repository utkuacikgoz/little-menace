import XCTest

/// Drives the real app through its accessibility tree. `-LMReset YES` starts from a fresh
/// The gremlin; `-LMScreen home` (DEBUG) sets level 4, two visit days and mid-range needs.
final class LittleMenaceUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(_ extra: [String] = [], reset: Bool = true) {
        app.launchArguments = (reset ? ["-LMReset", "YES"] : []) + extra
        app.launch()
        XCTAssertTrue(pet.waitForExistence(timeout: 10))
    }

    private var pet: XCUIElement { app.descendants(matching: .any)["pet"].firstMatch }
    private var buyButton: XCUIElement { app.descendants(matching: .any)["buy"].firstMatch }
    private var ownedMarker: XCUIElement { app.descendants(matching: .any)["owned"].firstMatch }
    private var petValue: String { (pet.value as? String) ?? "" }

    private func waitForValue(containing text: String, timeout: TimeInterval = 5) -> Bool {
        let predicate = NSPredicate(format: "value CONTAINS %@", text)
        let exp = expectation(for: predicate, evaluatedWith: pet)
        return XCTWaiter.wait(for: [exp], timeout: timeout) == .completed
    }

    // MARK: Home

    func testHomeShowsOnlyTheToy() {
        launch()
        for label in ["Feed", "Play", "Nap", "More", "Points"] {
            XCTAssertTrue(app.buttons[label].exists, "missing \(label)")
        }
        // Almost no words at rest: the need numbers under the buttons, plus at most a transient speech bubble.
        let words = app.staticTexts.matching(NSPredicate(format: "NOT (label MATCHES %@)", ".*[0-9]+%?"))
        XCTAssertLessThanOrEqual(words.count, 1, words.allElementsBoundByIndex.map(\.label).joined(separator: " | "))
    }

    func testPetDragAndFeedUntilFull() {
        launch()
        pet.tap()
        let center = pet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.1, thenDragTo: center.withOffset(CGVector(dx: 120, dy: -80)))
        XCTAssertTrue(pet.isHittable, "the gremlin springs back after a drag")

        // Fresh fullness is 60: two snacks reach Full, the third is refused.
        app.buttons["Feed"].tap()
        app.buttons["Feed"].tap()
        XCTAssertTrue(waitForValue(containing: "Full"))
        app.buttons["Feed"].tap()
        XCTAssertTrue(petValue.contains("Full"))
    }

    func testNamePromptAfterFirstPet() {
        launch()
        XCTAssertEqual(pet.label, "Your gremlin")
        pet.tap()
        let field = app.textFields["Name"]
        XCTAssertTrue(field.waitForExistence(timeout: 3), "prompt appears after the first pet")
        field.tap()
        field.typeText("Mo Fang")
        app.buttons["Save name"].tap()
        XCTAssertEqual(pet.label, "Mo Fang")

        app.terminate()
        launch(reset: false)
        XCTAssertEqual(pet.label, "Mo Fang", "name persists")
        pet.tap()
        XCTAssertFalse(app.textFields["Name"].waitForExistence(timeout: 2), "prompt is shown only once")
    }

    func testDragSnackToMouth() {
        launch()
        let feed = app.buttons["Feed"]
        feed.press(forDuration: 0.1, thenDragTo: pet)
        XCTAssertTrue(pet.isHittable)
    }

    func testNapWakeAndSurvivesRelaunch() {
        launch(["-LMScreen", "home"]) // energy 60, so a nap is allowed
        app.buttons["Nap"].tap()
        XCTAssertTrue(waitForValue(containing: "Asleep"))

        app.terminate()
        launch(reset: false)
        XCTAssertTrue(waitForValue(containing: "Asleep"), "a nap persists across termination")

        app.buttons["Wake"].tap()
        XCTAssertFalse(waitForValue(containing: "Asleep", timeout: 2))
    }

    func testCollectionPreviewsShowTheirPunchlineWithoutBuying() {
        launch()
        menu("Settings")
        app.buttons["Midnight Snack"].tap()
        let preview = app.buttons["Preview Fridge Raid"]
        XCTAssertTrue(preview.waitForExistence(timeout: 5))
        if !preview.isHittable { app.swipeUp() }
        preview.tap()
        let caption = app.staticTexts["collection-caption"]
        if !caption.isHittable { app.swipeDown() }
        XCTAssertTrue(caption.waitForExistence(timeout: 3))
        XCTAssertEqual(caption.label, "midnight snack run.")
        XCTAssertFalse(app.buttons["wear-collection"].exists, "previewing never grants ownership")
    }

    // MARK: Toys

    /// An element can exist under a screen that is still sliding away; wait until it can be tapped.
    /// Lists only build rows that are on screen: scroll gently until the element can be tapped.
    private func reveal(_ element: XCUIElement) -> Bool {
        _ = element.waitForExistence(timeout: 2)
        for _ in 0..<5 where !(element.exists && element.isHittable) { app.swipeUp(velocity: .slow) }
        return waitHittable(element)
    }

    private func waitGone(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let exp = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        return XCTWaiter.wait(for: [exp], timeout: timeout) == .completed
    }

    private func waitHittable(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        let exp = expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: element)
        return XCTWaiter.wait(for: [exp], timeout: timeout) == .completed
    }

    private func open(_ toy: String) {
        let play = app.buttons["Play"]
        XCTAssertTrue(waitHittable(play), "Play never became tappable")
        play.tap()
        let button = app.buttons[toy]
        XCTAssertTrue(button.waitForExistence(timeout: 3))
        button.tap()
    }

    private func finishRound(timeout: TimeInterval) {
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: timeout), "round never finished")
        done.tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
    }

    func testSnackTossRound() {
        launch(["-LMScreen", "home"])
        open("Snack toss")
        let snack = app.otherElements["Snack"].firstMatch
        XCTAssertTrue(snack.waitForExistence(timeout: 5))
        for _ in 0..<8 {
            if !snack.exists { break }
            snack.swipeUp(velocity: .fast)
        }
        finishRound(timeout: 10)
    }

    func testSockTugRound() {
        launch(["-LMScreen", "home"])
        open("Sock tug")
        let area = app.otherElements["Sock tug"].firstMatch
        XCTAssertTrue(area.waitForExistence(timeout: 5))
        let grip = area.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        grip.press(forDuration: 1.5, thenDragTo: grip.withOffset(CGVector(dx: 0, dy: 140)))
        finishRound(timeout: 30) // rounds end by 20 s at the latest
    }

    func testCushionHuntRound() {
        launch(["-LMScreen", "home"])
        open("Cushion hunt")
        let left = app.buttons["Cushion left"]
        XCTAssertTrue(left.waitForExistence(timeout: 5))
        let enabled = NSPredicate(format: "isEnabled == true")
        wait(for: [expectation(for: enabled, evaluatedWith: left)], timeout: 10)
        for name in ["Cushion left", "Cushion middle", "Cushion right"] {
            if app.buttons["Done"].exists { break }
            let b = app.buttons[name]
            if b.isEnabled { b.tap(); sleep(1) }
        }
        finishRound(timeout: 8)
    }

    func testClosingMidRoundLeavesNothingStuck() {
        launch(["-LMScreen", "home"])
        open("Sock tug")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Play"].waitForExistence(timeout: 5))
        // If the abandoned round were still active, the next one would be refused as busy.
        open("Cushion hunt")
        XCTAssertTrue(app.buttons["Cushion left"].waitForExistence(timeout: 5))
    }

    // MARK: Guide and points

    func testGuideShowsOnceOnFirstLaunch() {
        app.launchArguments = ["-LMReset", "YES", "-LMGuide", "YES"]
        app.launch()
        let next = app.buttons["Next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10), "a new player sees the guide")
        for _ in 0..<4 { next.tap() }
        let go = app.buttons["Let's go"]
        XCTAssertTrue(go.waitForExistence(timeout: 3))
        go.tap()
        XCTAssertTrue(waitGone(go), "the tour closes")
        XCTAssertTrue(pet.waitForExistence(timeout: 5))
        XCTAssertTrue(waitHittable(pet, timeout: 10), "the guide closes onto the home screen: \(app.debugDescription.replacingOccurrences(of: "\n", with: " ⏎ "))")

        app.terminate()
        launch(reset: false)
        XCTAssertFalse(app.buttons["Next"].waitForExistence(timeout: 2), "the guide is shown only once")
    }

    func testScoreOpensThePointsPage() {
        launch(["-LMScreen", "home"])
        let score = app.buttons["Points"]
        XCTAssertTrue(waitHittable(score))
        score.tap()
        XCTAssertTrue(app.navigationBars["Points"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()
        XCTAssertTrue(waitHittable(app.buttons["Feed"]))
    }

    // MARK: Sheets

    private func menu(_ item: String) {
        let more = app.buttons["More"]
        XCTAssertTrue(waitHittable(more), "More is ready before opening its menu")
        more.tap()
        let menu = app.collectionViews.containing(.button, identifier: item).firstMatch
        let b = menu.buttons[item]
        XCTAssertTrue(b.waitForExistence(timeout: 3))
        XCTAssertTrue(waitHittable(b), "\(item) is ready before selecting it")
        b.tap()
        XCTAssertTrue(waitGone(menu), "The menu closes after selecting \(item): \(app.debugDescription)")
    }

    func testWardrobeEquipAndPreview() {
        launch(["-LMScreen", "home"])
        menu("Wardrobe")
        let leaf = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Leaf'")).firstMatch
        XCTAssertTrue(leaf.waitForExistence(timeout: 3))
        leaf.tap()
        XCTAssertTrue(leaf.label.contains("wearing"))
        let nightcap = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Nightcap'")).firstMatch
        XCTAssertTrue(nightcap.exists, "paid items are visible after attachment")
        nightcap.tap()
        // Not owned: the preview shows the buy bar. Owned (e.g. a leftover sandbox purchase): it equips.
        let offered = buyButton.waitForExistence(timeout: 5)
        XCTAssertTrue(offered || nightcap.label.contains("wearing"), "paid item previews with a buy button, or equips if owned")
    }

    func testReviewerCanReachCollectionFromSettingsOnDayOne() {
        launch() // fresh: level 1, one visit
        menu("Settings")
        let row = app.buttons["Midnight Snack"]
        XCTAssertTrue(reveal(row), "Midnight Snack reachable in Settings")
        row.tap()
        let offered = buyButton.waitForExistence(timeout: 5)
        XCTAssertTrue(offered || ownedMarker.exists, "collection page shows the buy button, or 'Owned' if already bought")
    }

    func testSettingsResetNeedsConfirmation() {
        launch(["-LMScreen", "home"])
        menu("Settings")
        let startOver = app.buttons["Start Over"].firstMatch
        XCTAssertTrue(reveal(startOver), "Start Over reachable")
        startOver.tap()
        let title = app.staticTexts["Start over with a new gremlin?"]
        XCTAssertTrue(title.waitForExistence(timeout: 3), "the confirmation appears")
        // iOS 26 shows the dialog as a bubble without Cancel; tapping outside dismisses it.
        let cancel = app.buttons["Cancel"]
        if cancel.exists { cancel.tap() } else { app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap() }
        XCTAssertTrue(waitGone(title), "the dialog closes")
        let done = app.buttons["Done"]
        XCTAssertTrue(waitHittable(done))
        done.tap()
        XCTAssertTrue(waitHittable(pet), "Settings closes")
        XCTAssertTrue(waitForValue(containing: "Level 4"), "cancel keeps progress; the gremlin reads: \(petValue)")
    }

    func testDeniedNotificationsAreHandled() {
        launch()
        // Fallback: fires on the next interaction if the alert is not handled directly below.
        addUIInterruptionMonitor(withDescription: "Notifications") { alert in
            let deny = alert.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Don'")).firstMatch
            guard deny.exists else { return false }
            deny.tap()
            return true
        }
        menu("Settings")
        let toggle = app.switches["Reminders"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        // Tap the switch itself; tapping a SwiftUI toggle's centre can land on its label.
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deny = springboard.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Don'")).firstMatch
        if deny.waitForExistence(timeout: 10) {
            deny.tap()
        } else {
            app.navigationBars.firstMatch.tap() // lets the interruption monitor run
        }
        let note = app.buttons["Notifications are off in iOS Settings"]
        XCTAssertTrue(note.waitForExistence(timeout: 10), "denied permission is explained in Settings")
        XCTAssertEqual(toggle.value as? String, "0", "the toggle stays off when permission is denied")
    }

    func testShareCardRenders() {
        launch(["-LMScreen", "home"])
        menu("Share")
        XCTAssertTrue(app.buttons["Share"].waitForExistence(timeout: 5))
    }

    // MARK: Accessibility

    func testLargestTextSizeSheets() {
        launch(["-LMScreen", "home", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        menu("Stamps")
        // The stamp card's own content, not just some scroll view: container types differ across iOS versions.
        let week = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'stamps this week'")).firstMatch
        XCTAssertTrue(week.waitForExistence(timeout: 5),
                      "stamp card opens at the largest text size: \(app.debugDescription.replacingOccurrences(of: "\n", with: " ⏎ "))")
    }

    /// Xcode's built-in audit on each screen. Issues are logged as AUDIT lines for triage;
    /// categories that are genuine bugs for this app fail the test.
    func testAccessibilityAudit() throws {
        launch(["-LMScreen", "home"])
        var failures: [String] = []
        func audit(_ screen: String) throws {
            try app.performAccessibilityAudit { issue in
                let line = "AUDIT [\(screen)] \(issue.auditType) \(issue.compactDescription) — \(issue.element?.label ?? "?")"
                print(line)
                if [.hitRegion, .sufficientElementDescription].contains(issue.auditType) { failures.append(line) }
                return true
            }
        }
        try audit("home")
        menu("Stamps")
        try audit("stamps")
        app.swipeDown(velocity: .fast)
        menu("Wardrobe")
        try audit("wardrobe")
        app.swipeDown(velocity: .fast)
        menu("Settings")
        try audit("settings")
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}
