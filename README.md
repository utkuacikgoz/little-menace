# Little Menace

A native iPhone pet toy. It has one chaotic little gremlin that players name themselves, one bold background, and almost no text. It is written in SwiftUI for iOS 17+, with no third-party packages, no accounts and no backend.

> **Honest status:** this repository started empty. The prototype, the original `DESIGN.md`/`GAMEPLAY.md` and the generated mascot art named in the brief were not present, so everything here was rebuilt from the brief. The character uses an animated vector rig. The rules engine (`MenaceCore`) is compiled and tested. The iOS app builds and launches in CI on simulators, but nobody has played it on a device yet (see *Validation*).

## Layout

```
LittleMenace.xcodeproj    App target (Xcode 16+, synchronized App/ folder) + shared scheme
App/                      SwiftUI app: Home, gremlin rig, Activities, Sheets, Services, assets, sounds
MenaceCore/               Swift package: state, time model, rules, progression, save store (+ tests)
Config/LittleMenace.storekit   Local StoreKit sandbox config (one non-consumable)
.github/workflows/ios.yml  macOS CI: core tests, simulator build, screenshots
DESIGN.md / GAMEPLAY.md   Design and rules as built
docs/AppStore.md          Draft metadata + privacy answers
```

## Build and run

1. Open `LittleMenace.xcodeproj` in Xcode 16 or later.
2. Pick the **LittleMenace** scheme and an iPhone simulator, then Run.
3. Purchases use the local StoreKit config, so no real money is involved. If the store shows "Store unavailable", set **Scheme › Run › Options › StoreKit Configuration** to `Config/LittleMenace.storekit`. The scheme references it, but Xcode's relative-path handling for that field varies.
4. For a device: set your team under Signing. The bundle ID is `com.belevate.littlemenace`.
5. TestFlight: run the **TestFlight** workflow from the Actions tab. It needs the `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_P8` repository secrets (an App Store Connect API key with the Admin role).

Core tests run anywhere Swift runs:

```
./scripts/test-core.sh        # = swift test --package-path MenaceCore
```

## What works

- **Character rig.** A parametric vector gremlin with 17 animated parameters and 18 reaction poses: idle, attention, touch, feed, play, sleepy, asleep, wake, grumpy wake, mischief, refusals, win/lose and more. Breathing, blinking, tail wag, and eyes that track your finger and the snack.
- **Touch.** Tap to pet. Drag stretches the gremlin with a bounded rubber band and springs back on release, and a cancelled drag resets cleanly. Long press plays a reaction.
- **Care.**
  - Feed: tap the cookie, or drag it to the gremlin's mouth.
  - Nap and wake, with refusals at the thresholds.
  - A capped, floored, clock-safe time model. Naps continue while the app is closed.
- **Three toys:** snack toss (analytic catch physics), sock tug (timing-based; nonstop yanking loses), cushion hunt. Each has a replay/done result card and an accessible path.
- **Progression:** XP and levels with unlocks, 10 discoveries, one deterministic daily challenge, and a weekly stamp card with a 3-stamp bonus and a 5-stamp gift. Every reward goes through a grant ledger, so each is granted once.
- **Mischief:** 12 authored two-choice events that nudge a −1…+1 personality.
- **Wardrobe:** hats, neckwear, backgrounds and tug socks. Items unlock by level or weekly gift. The paid set can be previewed.
- **Reminders:** optional, offered once after a useful moment, one per day at most, stopping after 3 days away. There is also a nap-end note. Denied permission is handled.
- **Share card:** rendered from the actual state and sent to the system share sheet.
- **Midnight Snack collection:** StoreKit 2 with verified transactions, pending/cancel/failure states, restore, `Transaction.updates`, and revocation that un-equips paid items. It is shown only in the Wardrobe, and only after level 3 plus visits on 2 days.
- **Settings:** sound, haptics, reminders plus time, restore, privacy/support links, and a confirmed reset.
- **Persistence:** a versioned JSON envelope with lenient decoding, clamping, a migration chain, a backup of the last good save, and quarantine (never deletion) of unreadable or future-version files.
- **Sound:** 8 small synthesized effects in the ambient session, so they respect the silent switch.

## Validation

| Check | Result |
|---|---|
| `MenaceCore` tests (Xcode 26.6, macOS) | **59/59 pass**: time rules, clock changes, time zones, rewards granted once, migrations, corrupt-save recovery, interrupted/duplicate rounds, tug gesture cancellation and frame-rate independence, entitlements/revocation, offer gating, reminder planning |
| iOS app compile | **Builds** with Xcode on GitHub's macOS 15 runner (`.github/workflows/ios.yml`), on every push |
| Simulator launch | Launches without crashing on iPhone SE (3rd gen) and iPhone 16 Pro Max. The error-level log lines are only standard simulator noise from Apple frameworks (audio plugin factory, eligibility plist, CoreFS cache), with none from app code. |
| Screenshots | `docs/screenshots/` holds 32 numbered shots: every screen and interaction state (naming, feeding, refusals, play picker, all three toys, win/lose cards, mischief, sleep and grumpy wake, reminder offer, every wardrobe tab, a paid preview, Midnight Snack, stamps, share, settings, dark mode, SE and largest text). Regenerate them by running the iOS build workflow manually. |
| Interactive play, VoiceOver, Reduce Motion, denied notifications, relaunch, offline | **Not yet inspected by a person.** The screenshots are static launches, and these paths are implemented as described in DESIGN.md. |
| Haptics | Needs a physical device |
| Purchases | Only the StoreKit local config exists. No sandbox or App Store Connect products have been created. |

## Known gaps / next steps

- **Art:** the gremlin uses a shaded vector rig with amber eyes and a fur silhouette. Further art work should preserve its pose parameters and wearable alignment.
- **Speech lines:** 328 authored contextual lines plus 36 mischief lines. The last 50 utterances are saved with the pet; small reaction pools cycle oldest-first after exhaustion. Idle speech responds to needs, time, personality, outfits and games actually played.
- **Links:** privacy and support pages are in `docs/Privacy.md` and `docs/Support.md`, linked from Settings.
- **Analytics:** none. Add them only with a documented, minimal event list.
- **Android:** not started, since it is not agreed.

## Personality and first collection update

The first paid offer remains **Midnight Snack**, a permanent collection with a proposed US launch price of **$3.99**. The app always displays Apple's localized product price; the local configuration does not create a live product or set its production price. See `docs/Monetization.md` for setup and the first experiment.

- Speech appears briefly beneath the character, with no extra home-screen panels. Care actions and refusals speak; idle lines surface occasionally while the home screen is visible.
- Naps recover four energy per minute and finish within 25 minutes. Each game costs six energy. The first mischief event appears after 90 seconds; subsequent events remain spaced out.
- Collection previews show the performance, prop and punchline together. A purchase is a separate explicit action. Owners can wear the whole collection, and everyone can restore from the collection page.
- Store failures never imply that the user is necessarily offline; the page offers a retry and keeps previews available. Already-owned and pending purchases cannot be started again.
- CI now propagates build/test command failures instead of allowing failed commands to produce a green check.
