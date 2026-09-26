import SwiftUI
import UIKit
import MenaceCore

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    var text: String?
    let spoken: String
}

struct Bubble: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

/// Owns the rules engine, persistence and feedback. Views read it and call intents.
@MainActor
@Observable
final class GameModel {
    private(set) var game: Game
    private(set) var now = Date()
    private(set) var transient: Reaction?
    /// A collection reaction in progress overrides everything else.
    private(set) var specialPose: GremlinPose?
    private(set) var specialProp: String?
    private(set) var specialLine: String?
    var look: CGSize = .zero
    private(set) var bubble: Bubble?
    private(set) var toast: Toast?
    var activity: ActivityKind?
    private(set) var session: ActivitySession?
    var showReminderOffer = false
    var showNamePrompt = false
    var homeObscured = false
    private(set) var notificationsDenied = false

    let purchases = PurchaseManager()
    let sounds = SoundPlayer()
    let haptics = Haptics()
    @ObservationIgnored private let reminders = ReminderScheduler()
    @ObservationIgnored private let store = SaveStore.appDefault()
    @ObservationIgnored private var rng = SystemRandomNumberGenerator()
    @ObservationIgnored private var reactionTask: Task<Void, Never>?
    @ObservationIgnored private var bubbleTask: Task<Void, Never>?
    @ObservationIgnored private var toastQueue: [Toast] = []
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var specialTask: Task<Void, Never>?

    var state: PetState { game.state }

    init() {
        #if DEBUG
        // UI tests: `-LMReset YES` starts from a fresh the gremlin.
        if UserDefaults.standard.bool(forKey: "LMReset") { store.wipe() }
        #endif
        let (loaded, _) = store.load(now: Date())
        game = Game(state: loaded)
        applyPrefs()
        handle(game.tick(now: now))
        if game.state.pendingWake {
            game.acknowledgeWake()
            react(.wake, for: 2)
        }
        purchases.onEntitlementsChanged = { [weak self] owned in self?.entitlementsChanged(owned) }
    }

    // MARK: Lifecycle

    func start() async {
        await purchases.refreshEntitlements()
        await purchases.loadProducts()
        notificationsDenied = state.prefs.remindersEnabled ? !(await reminders.isAuthorized()) : false
        if bubble == nil && !homeObscured { say(.idle) }
    }

    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .active:
            refreshClock()
            startTicker()
        case .background:
            // A round interrupted by leaving the app is dropped: no cost, no reward.
            if session != nil || game.state.session != nil { cancelActivity() }
            ticker?.cancel()
            save()
            replanReminders()
        default:
            break
        }
    }

    /// Time zone or clock changed, or the app returned to the foreground.
    func refreshClock() {
        NSTimeZone.resetSystemTimeZone()
        game.days = DayClock(timeZone: .current)
        now = Date()
        handle(game.tick(now: now))
        if game.state.pendingWake {
            game.acknowledgeWake()
            react(.wake, for: 2)
        }
        save()
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(20))
                guard let self, !Task.isCancelled else { return }
                self.now = Date()
                self.handle(self.game.tick(now: self.now))
                if self.game.state.pendingWake {
                    self.game.acknowledgeWake()
                    self.react(.wake, for: 2)
                    self.sounds.play(.pop)
                    self.say(.wake)
                }
                if !self.homeObscured && self.activity == nil && !self.showNamePrompt && !self.showReminderOffer && self.bubble == nil && self.specialPose == nil {
                    self.say(.idle, chance: 0.55)
                }
            }
        }
    }

    // MARK: Pose

    var pose: GremlinPose {
        if state.isAsleep { return .pose(for: .asleep) }
        if let specialPose { return specialPose }
        var p = transient.map(GremlinPose.pose(for:)) ?? GremlinPose.base(asleep: state.isAsleep, energy: state.needs.energy)
        if transient == nil || transient == .attention { p.look = look }
        return p
    }

    func react(_ reaction: Reaction, for seconds: Double = 1.4) {
        cancelSpecial()
        transient = reaction
        reactionTask?.cancel()
        reactionTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.transient = nil
        }
    }

    /// A drag was released or cancelled: drop the "watching your finger" face.
    func endAttention() {
        if transient == .attention { transient = nil }
        look = .zero
    }

    func say(_ reaction: Reaction, chance: Double = 1) {
        guard Double.random(in: 0..<1, using: &rng) < chance,
              let line = Lines.next(for: reaction, state: &game.state,
                                    hour: game.days.hour(Date()), using: &rng) else { return }
        showLine(line)
        save()
    }

    private func showLine(_ line: String, duration: Double = 5) {
        bubbleTask?.cancel()
        bubble = Bubble(text: line)
        bubbleTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.bubble = nil
        }
        UIAccessibility.post(notification: .announcement, argument: "\(state.titleName): \(line)")
    }

    func cancelSpecial() {
        specialTask?.cancel()
        if specialLine != nil { bubbleTask?.cancel(); bubble = nil }
        specialLine = nil
        specialPose = nil
        specialProp = nil
    }

    /// Long press: an owned collection reaction, or just a sly grin.
    func longPress() {
        guard !state.isAsleep else { return }
        let owned = Catalog.ownedReactions(entitlements: entitlements)
        guard let id = owned.randomElement(using: &rng) else {
            react(.mischief, for: 1.2)
            say(.mischief, chance: 0.5)
            return
        }
        performSpecial(id)
    }

    /// Plays an authored reaction. Also used for the wardrobe preview before purchase.
    func performSpecial(_ id: String) {
        guard let special = SpecialReaction.find(id) else { return }
        specialTask?.cancel()
        specialProp = special.prop
        specialLine = special.line
        showLine(special.line, duration: special.beats.reduce(0) { $0 + $1.seconds } + 2)
        sounds.play(.boing)
        specialTask = Task { [weak self] in
            for beat in special.beats {
                guard let self, !Task.isCancelled else { return }
                self.specialPose = beat.pose
                self.haptics.play(.squish, intensity: 0.5)
                try? await Task.sleep(for: .seconds(beat.seconds))
            }
            guard let self, !Task.isCancelled else { return }
            self.specialPose = nil
            self.specialProp = nil
        }
    }

    // MARK: Care intents

    func pet() {
        let out = game.pet(now: Date())
        if state.isAsleep {
            say(.asleep, chance: 0.3)
            haptics.play(.squish, intensity: 0.4)
        } else {
            react(.touch)
            haptics.play(.squish)
            sounds.play(.pop)
            say(.touch, chance: 0.75)
            // Meet it first, then name it: the prompt appears once, after the first pet.
            if state.name.isEmpty && !state.namePromptShown {
                game.state.namePromptShown = true
                showNamePrompt = true
            }
        }
        handle(out.events)
        save()
    }

    /// Returns whether the gremlin ate. The feed gesture uses it to decide where the snack goes.
    @discardableResult
    func feed() -> Bool {
        let out = game.feed(now: Date())
        finishCare(out)
        if out.refusal == nil {
            sounds.play(.chomp)
            haptics.play(.thud, intensity: 0.6)
        }
        return out.refusal == nil
    }

    func toggleSleep() {
        let out = state.isAsleep ? game.wake(now: Date()) : game.sleep(now: Date())
        finishCare(out, duration: out.reaction == .asleep ? 0.1 : 2)
        if out.refusal == nil {
            sounds.play(state.isAsleep ? .snore : .boing)
            haptics.play(.squish, intensity: 0.5)
            if state.isAsleep { offerRemindersIfUseful() }
        }
    }

    private func finishCare(_ out: Outcome, duration: Double = 1.4) {
        cancelSpecial()
        if let refusal = out.refusal {
            react(refusal.reaction, for: 1.6)
            say(refusal.reaction)
            haptics.play(.nope)
        } else {
            if out.reaction != .asleep { react(out.reaction, for: duration) } else { transient = nil }
            say(out.reaction)
        }
        handle(out.events)
        save()
        replanReminders()
    }

    // MARK: Play intents

    func startActivity(_ kind: ActivityKind) {
        switch game.startActivity(kind, now: Date()) {
        case .success(let s):
            session = s
            activity = kind
            haptics.play(.tap)
        case .failure(let refusal):
            react(refusal.reaction, for: 1.6)
            say(refusal.reaction)
            haptics.play(.nope)
        }
    }

    /// Returns the XP earned so the activity can show it.
    @discardableResult
    func finishActivity(_ result: ActivityResult) -> Int {
        guard let s = session, s.kind == result.kind else { return 0 }
        let out = game.finishActivity(s, result: result, now: Date())
        guard out.refusal == nil else { return 0 }
        session = nil
        sounds.play(result.won ? .win : .lose)
        haptics.play(result.won ? .success : .tap)
        handle(out.events)
        save()
        return out.events.reduce(0) { total, e in
            if case .xp(let n) = e { return total + n }
            return total
        }
    }

    /// Leaving a round early (close button, interruption, backgrounding).
    func cancelActivity() {
        game.cancelActivity()
        session = nil
        activity = nil
    }

    func closeActivity(won: Bool?) {
        activity = nil
        if let won { react(won ? .win : .lose, for: 1.8); say(won ? .win : .lose, chance: 0.6) }
        offerRemindersIfUseful()
    }

    // MARK: Mischief

    var pendingMischief: MischiefEvent? { game.pendingMischief(now: now) }

    func resolveMischief(_ event: MischiefEvent, indulge: Bool) {
        let out = game.resolveMischief(event.id, indulge: indulge, now: Date())
        guard out.refusal == nil else { return }
        let choice = indulge ? event.indulge : event.redirect
        react(out.reaction, for: 2)
        showLine(choice.line)
        sounds.play(indulge ? .boing : .pop)
        haptics.play(.success)
        handle(out.events)
        save()
    }

    // MARK: Events → feedback

    private func handle(_ events: [GameEvent]) {
        for event in events {
            switch event {
            case .xp:
                break
            case .levelUp(let level):
                enqueue(Toast(symbol: "arrow.up.circle.fill", text: "\(level)", spoken: "Level \(level)"))
                react(.levelUp, for: 2)
            case .unlocked(let id):
                let name = Catalog.item(id)?.name ?? id
                enqueue(Toast(symbol: "gift.fill", text: name, spoken: "Unlocked \(name)"))
            case .discovery(let d):
                enqueue(Toast(symbol: d.symbol, text: nil, spoken: "Discovery: \(d.spoken)"))
            case .challengeComplete(let kind):
                enqueue(Toast(symbol: "checkmark.seal.fill", text: nil, spoken: "Daily challenge done: \(kind.spoken)"))
            case .stamp(let gold):
                enqueue(Toast(symbol: gold ? "seal.fill" : "seal", text: "\(state.stamps.days.count)", spoken: "Stamp \(state.stamps.days.count) this week"))
            case .stampBonus:
                enqueue(Toast(symbol: "sparkles", text: nil, spoken: "Weekly bonus"))
            case .weeklyGift(let id):
                let name = Catalog.item(id)?.name ?? id
                enqueue(Toast(symbol: "gift.fill", text: name, spoken: "Weekly gift: \(name)"))
            case .autoWoke:
                break
            }
        }
    }

    private func enqueue(_ t: Toast) {
        toastQueue.append(t)
        if toastTask == nil { showNextToast() }
    }

    private func showNextToast() {
        guard !toastQueue.isEmpty else {
            toast = nil
            toastTask = nil
            return
        }
        let next = toastQueue.removeFirst()
        toast = next
        sounds.play(.stamp)
        UIAccessibility.post(notification: .announcement, argument: next.spoken)
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            self?.showNextToast()
        }
    }

    // MARK: Wardrobe

    var entitlements: Set<String> { purchases.entitlements }

    func owns(_ item: Item) -> Bool { Catalog.isOwned(item, state: state, entitlements: entitlements) }

    func equip(_ item: Item?, in slot: Slot) {
        if let item, !owns(item) { return }
        game.state.wardrobe.equip(item?.id, in: slot)
        haptics.play(.tap)
        save()
    }

    private func entitlementsChanged(_ owned: Set<String>) {
        if Catalog.sanitize(&game.state, entitlements: owned) { save() }
    }

    // MARK: Settings

    func setSound(_ on: Bool) { game.state.prefs.sound = on; applyPrefs(); save() }
    func setHaptics(_ on: Bool) { game.state.prefs.haptics = on; applyPrefs(); save() }

    func setReminders(_ on: Bool) async {
        if on {
            let granted = await reminders.requestPermission()
            game.state.prefs.remindersEnabled = granted
            notificationsDenied = !granted
        } else {
            game.state.prefs.remindersEnabled = false
            notificationsDenied = false
        }
        save()
        replanReminders()
    }

    func setReminderTime(_ date: Date) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        game.state.prefs.reminderHour = c.hour ?? 18
        game.state.prefs.reminderMinute = c.minute ?? 30
        save()
        replanReminders()
    }

    func rename(_ name: String) {
        game.state.rename(name)
        showNamePrompt = false
        save()
        replanReminders()
    }

    func dismissReminderOffer() {
        showReminderOffer = false
    }

    private func offerRemindersIfUseful() {
        guard ReminderPolicy.shouldOffer(state) else { return }
        game.state.prefs.reminderOfferShown = true
        showReminderOffer = true
        save()
    }

    func reset() {
        cancelSpecial()
        reactionTask?.cancel()
        bubbleTask?.cancel()
        game.reset(now: Date())
        Catalog.sanitize(&game.state, entitlements: entitlements)
        session = nil
        activity = nil
        transient = nil
        bubble = nil
        showNamePrompt = false
        showReminderOffer = false
        save()
        replanReminders()
        react(.wake, for: 2)
    }

    #if DEBUG
    /// Screenshot tours: `-LMScreen <name>` launch argument (DEBUG builds only).
    /// Returns a sheet for HomeView to present, if the screen is one.
    func applyDebugLaunch() -> HomeSheet? {
        guard let screen = UserDefaults.standard.string(forKey: "LMScreen") else { return nil }
        game.state.xp = max(game.state.xp, Tuning.xpForLevel(4))
        game.state.counters.visitDays = max(game.state.counters.visitDays, 3)
        game.state.needs = Needs(fullness: 50, energy: 60, joy: 60)
        if let theme = UserDefaults.standard.string(forKey: "LMTheme") { game.state.wardrobe.theme = theme }
        if let hat = UserDefaults.standard.string(forKey: "LMHat") { game.state.wardrobe.hat = hat }
        switch screen {
        case "asleep": _ = game.sleep(now: Date())
        case "grumpy":
            _ = game.sleep(now: Date())
            _ = game.wake(now: Date())
            react(.grumpyWake, for: 30)
        case "mischief", "mischiefSheet": game.state.mischief.nextAt = Date().addingTimeInterval(-1)
        case "touch": react(.touch, for: 30)
        case "feed":
            _ = feed()
            react(.feed, for: 30)
        case "refuse":
            game.state.needs.fullness = 95
            _ = feed()
            react(.refuseFood, for: 30)
        case "dialogue": showLine("my alibi is adorable.", duration: 30)
        case "namePrompt": showNamePrompt = true
        case "reminderOffer": showReminderOffer = true
        case "reminders":
            game.state.prefs.remindersEnabled = true
            return .settings
        default: break
        }
        if let kind = ActivityKind(rawValue: screen) { startActivity(kind) }
        return HomeSheet(rawValue: screen)
    }
    #endif

    // MARK: Persistence

    private func applyPrefs() {
        sounds.enabled = game.state.prefs.sound
        haptics.enabled = game.state.prefs.haptics
    }

    private func save() {
        do {
            try store.save(game.state)
        } catch {
            // Disk full or similar: keep playing from memory, try again on the next change.
        }
    }

    private func replanReminders() {
        let plan = ReminderPolicy.plan(state, now: Date(), days: game.days)
        let title = state.name.isEmpty ? "Little Menace" : state.name
        Task { await reminders.apply(plan, title: title) }
    }
}
