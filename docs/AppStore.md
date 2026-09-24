# App Store draft: metadata and privacy

**Draft only. Nothing has been submitted, and no paid service has been set up.** Names, prices and copy are provisional.

## Metadata

- **Name:** Little Menace (working name)
- **Subtitle:** A tiny gremlin who lives in your phone
- **Category:** Games › Casual (secondary: Entertainment)
- **Age rating:** 4+ (no violence, no user-generated content, no web access, no chat)
- **Promotional text:** Feed it, tug a sock with it, find it under a cushion. Crumb is small, warm, and up to something.
- **Description:**

  Crumb is a chaotic little gremlin with a soft spot for you.

  Toss snacks into its mouth. Win a sock tug by pulling at exactly the right moment. Follow the right cushion while Crumb hides underneath. Pet it, stretch it, tuck it in for a nap.

  Every so often Crumb gets up to something. How you respond shapes whether it grows into a certified menace or a secret softie.

  Collect a stamp for every day you play and earn a small gift each week. Nobody loses a streak. Crumb never gets sick and never guilt-trips you.

  Everything runs on your phone. No account, no ads.

  Optional: the Midnight Snack collection adds a nightcap, moon charm, starry background, glow sock and three midnight reactions. Preview it all on Crumb before you decide.

- **Keywords:** virtual pet, gremlin, cute, tamagotchi, pet game, toy, cozy, mischief
- **In-app purchase:** Midnight Snack, non-consumable, Family Sharing on. The price is to be decided; $3.99 is a sandbox test input only.
- **Screenshots needed (6.9" and 6.5" iPhone):** home in Tangerine, sock tug, cushion hunt, wardrobe preview, share card. Capture them from the simulator, following `README.md`.
- **Support URL / Privacy URL:** required before submission. Placeholders live in `App/Sheets/SettingsView.swift` (`AppLinks`).

## App Privacy ("nutrition label")

This is based on what the code actually does:

| Question | Answer |
|---|---|
| Data collected by the developer | **None** |
| Tracking | No (`NSPrivacyTracking` = false) |
| Third-party SDKs | None. There are no package dependencies besides the local `MenaceCore`. |
| Analytics | None. There is no analytics code. |
| Network use by the app | Only the StoreKit calls Apple makes on the app's behalf. The app has no servers. |

What is stored, and where:
- Crumb's state is one JSON file in Application Support: `pet.json`, plus `pet.backup.json` and any quarantined unreadable saves. It stays on the device. It is included in the normal iOS device backup, but the app itself sends nothing.
- Purchase records come from StoreKit (Apple). The app does not store receipts.
- Reminder notifications are scheduled locally with `UNUserNotificationCenter`. Nothing is sent to a server.

The share card is generated on the device and passed to the system share sheet. It is shared only if the user picks a destination.

`App/PrivacyInfo.xcprivacy` declares no tracking, no collected data, and no required-reason APIs. Re-check this whenever a dependency or API is added: for example, `UserDefaults` would need `NSPrivacyAccessedAPICategoryUserDefaults`.

## Review notes (for App Review)

- Reset is in Settings › Start Over, and needs confirmation. Purchases are not affected.
- To test the purchase from a fresh install: open **… › Settings › Midnight Snack**. This page is always available; it previews the items and reactions on Crumb and has the Buy button. (For players, the Wardrobe shows the collection only after level 3 and visits on 2 days, and it is never promoted on the home screen.) Restore Purchases is on the same Settings screen.
- Notifications are optional and are only requested after the user opts in inside the app.
