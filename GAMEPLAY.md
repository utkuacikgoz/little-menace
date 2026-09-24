# Little Menace — gameplay

The gremlin has no fixed name. After the first pet, a one-line prompt asks the player to name it (skippable, and editable later in Settings). Until then, labels and speech say "your gremlin".

Rebuilt from the owner brief. The original `GAMEPLAY.md` was not in this repository. Every number below is **provisional** and lives in `MenaceCore/Sources/MenaceCore/Tuning.swift`.

## Care

Three hidden needs, each 0–100. There are no bars on the home screen. The gremlin's face shows them, and the rings around the three buttons show them faintly.

| Need | Awake, per hour | Asleep, per hour | Absence floor |
|---|---|---|---|
| Fullness | −8 | −4 | 20 |
| Energy | −5 | +45 | 20 |
| Joy | −6 | 0 | 25 |

- **Feed**: +25 fullness, +4 joy. Refused at ≥ 90 fullness: the gremlin turns its head and the snack bounces back. There are two ways to feed: tap the cookie (auto-toss), or drag the cookie to the gremlin's mouth. The gremlin's mouth opens as the cookie gets close.
- **Pet** (tap the gremlin): +2 joy. Drag the gremlin to stretch it (the stretch is rubber-banded and bounded), and release for a springy reaction. **Long press**: a sly grin, or an owned collection reaction.
- **Nap**: refused at ≥ 75 energy. A nap ends by itself at full energy or after 150 minutes. Waking the gremlin in the first 5 minutes gets a grumpy face and has no other cost.
- **Play**: costs 12 energy and 6 fullness, and gives up to 14 joy. Refused below 15 energy ("too sleepy").
- Nothing else can happen while a round is running. Feed, nap and a second round all return `busy`.

## Time model (`TimeModel.advance`)

- Needs are simulated from `lastSimulated` to now, and elapsed time is **capped at 8 h**. Coming back after a week feels the same as coming back after 8 hours.
- Passing time never takes a need below its absence floor, and never lowers a need that is already below the floor. Play can. Time cannot. The gremlin never dies, runs away, or gets sick.
- **Clock set backwards**: no time passes, and the anchor moves back to the new "now". A nap start in the "future" is pulled back to now.
- **Clock set forwards**: covered by the same 8 h cap.
- **Time zones**: day and week keys use the device's *current* zone (ISO-8601 weeks, Monday first). Every day and week reward is recorded in a grant ledger (`challenge:2026-09-24`, `week:2026-W39:gift`). Travelling across midnight twice therefore never pays twice.
- **Termination/backgrounding**: state is saved after every action and on backgrounding. A round in progress is **not** persisted. If the app is killed or backgrounded mid-round, the round is dropped: no cost, no reward. A nap *is* persisted and keeps running while the app is closed.

## Toys (three short, replayable rounds)

Each one is fun without rewards. XP is shown only on the small result card.

1. **Snack toss**: The gremlin sways at the top of the screen. Flick cookies up from the bottom, 8 per round. Catches are decided at launch by solving the arc against the gremlin's known sway, so frame rate never changes the result. Won at 5 or more catches. VoiceOver and Switch Control get a "Throw to the gremlin" action that aims and can still miss.
2. **Sock tug**: drag the sock down. The gremlin alternates strong pulls (1.3–2.3 s) with 0.75 s tired windows. The tired window is telegraphed by the gremlin's face, a haptic tick, and a VoiceOver "Now!".
   - Pulling in a tired window wins ground fast.
   - Holding light tension during strong pulls is fine. Yanking hard during strong pulls makes the sock slip. Nonstop yanking **loses**, and a test checks this.
   - Rounds last up to 20 s. A cancelled gesture resets the pull to 0 (`@GestureState`).
3. **Cushion hunt**: The gremlin peeks from one of three cushions, then the cushions swap 6 times (4 slower swaps with Reduce Motion). You get two guesses. Finding the gremlin on the first try is the best result.

## Progression

- **XP**:
  - Round: 8 + up to 12 by quality.
  - Feed: 2. Pet: 1. Feed and pet XP share a cap of **20 care XP per day**, so tapping can't grind levels.
  - Mischief choice: 5. Discovery: 15. Daily challenge: 30.
- **Levels**: level *n* needs `20·(n−1)·n` XP (40, 120, 240, 400…). Unlocks:
  - Level 2: Leaf hat
  - Level 3: Scarf
  - Level 4: Argyle sock
  - Level 5: Bubblegum background
- **Discoveries** (10, each granted once): first snack, first nap, first tug win, perfect toss, first-try find, playing after midnight, menace personality, softie personality, seven stamps in a week, five visit days. Undiscovered ones show as "?".

## Daily challenge

There is one challenge per local day, picked by a stable hash of the date (the same for everyone):
- catch 6 in one toss
- win a tug
- find the gremlin on the first try
- pet 8 times
- a proper nap (5 min or more)
- play all three games

Completing it grants 30 XP and a **gold stamp** once. It is shown only as an icon and progress pips on the stamp card.

## Weekly stamp card

- 7 slots, Monday to Sunday. Finishing any round stamps the day, and the daily challenge makes that stamp gold.
- **3 stamps**: +40 XP bonus. **5 stamps**: the weekly gift, a free cosmetic from a rotation (Paper Crown, Bell, Bow). Once you own all three gifts, the gift becomes 60 XP instead.
- Each reward is granted once per ISO week. Missing days removes nothing. There are no streaks.

## Mischief events

- 12 authored events. The first comes 15 minutes after first launch, then one every 3–5 hours (deterministic jitter). An event appears only while the gremlin is awake and idle.
- The only on-screen sign is a small bobbing prop next to the gremlin. Tapping it shows one line and two icon choices:
  - **indulge** (+personality, toward menace)
  - **redirect** (−personality, toward sweet)
- Both choices are good outcomes. Personality runs from −1 to +1 and changes the gremlin's idle lines and the share-card title. Events don't repeat within the last 6.

## Reminders

- **Off by default.** A single soft offer ("Nudge me later?") appears once, after a useful moment: starting a nap or finishing 3 rounds. The iOS permission prompt appears only if the player taps ✓.
- **Plan**:
  - at most one nudge per day, at the player's chosen time
  - never on the current day
  - only 3 days ahead, re-planned on every visit, so an absent player gets 3 friendly nudges and then silence
  - plus one "(name) is awake" note at the expected nap end
- There is no guilt, distress, or "your gremlin misses you". If permission is denied, Settings says so and links to iOS Settings.

## Sharing

The menu has a **Share** item. It renders a 1080×1350 card from the real state: current pose, outfit, theme, name, level, stamps, discoveries and personality title. The card goes to the system share sheet, and nothing is posted automatically.

## Paid collection (hypothesis, sandbox only)

- **Midnight Snack**, `app.littlemenace.collection.midnight`, non-consumable. The sandbox price of $3.99 is a test input, not an approved price.
- Contents:
  - Nightcap, Moon Charm, Midnight background (starry)
  - **Glow Sock**, a themed toy variation for sock tug
  - three authored multi-beat reactions: Fridge Raid, Moon Howl, Blanket Cape
- In the **Wardrobe**, the collection appears only after attachment: level ≥ 3 **and** visits on ≥ 2 different days. It is also always reachable from **Settings › Midnight Snack**, a quiet page that lets anyone, including App Review, preview it and buy it. It never appears on the home screen.
- Every item and every reaction can be **previewed on the gremlin** before buying. Buying is a separate, explicit tap on the localized price.
- Normal care, all three toys, progression and weekly gifts are free.
- Handling:
  - StoreKit 2, with only verified transactions counted
  - pending (Ask to Buy) is shown as "Waiting for approval"
  - cancel returns to idle, and failures show the system message
  - `Transaction.updates` is observed
  - revoked/refunded purchases un-equip paid items automatically (`Catalog.sanitize`)
  - Settings has Restore Purchases (`AppStore.sync`)

Not built, by decision: currency, loot boxes, ads, subscriptions, accounts, cloud sync, multiplayer, AI chat.
