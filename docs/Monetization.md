# Little Menace: first revenue experiment

## Offer

Launch one permanent collection: **Midnight Snack**, proposed US price **$3.99**. Product ID: `com.belevate.littlemenace.midnight`. Type: non-consumable. Enable Family Sharing if the App Store Connect setup supports the intended release.

Included: nightcap, moon charm, starry background, glow sock, Fridge Raid, Moon Howl, Blanket Cape. All reactions can be previewed. A preview neither equips an unowned item nor purchases anything. Owners can equip the collection together. Refunded or revoked items are removed from the equipped outfit.

Keep ordinary dialogue, care, existing games, progression and earned cosmetics free. Keep the day-two/level-three wardrobe discovery rule. Settings remains an always-available, quiet path to previews, purchase and restore. No recurring billing, paid food, stamina refills, ads or paid streak repair.

## Production setup still required

The repository cannot provision a product or approve agreements in the owner's App Store Connect account. Before charging money:

1. Configure the production bundle ID, product record, localized description and US $3.99 base price. Complete the account's agreements/tax/banking requirements.
2. Review the public support and privacy pages in this repository and use their URLs in App Store Connect.
3. Exercise purchase, cancellation, pending approval, restore after reinstall, and refund/revocation in Apple's sandbox on a physical device. Local StoreKit tests are not a substitute for this step.
4. Ensure screenshots and purchase description depict the actual included collection. Submit the product with the app when appropriate.

Do not hardcode the price in SwiftUI. Display `Product.displayPrice`. If the store is unavailable, keep previews usable and allow retry; never show a fake price or pretend a purchase succeeded.

## Measure before expanding

First observe whether players return, try the collection, purchase, and keep using the purchased items. Start with one price and one real offer; do not split a tiny test group into many variants. No analytics service has been added in this update. Any future instrumentation needs a minimal event list and updated privacy disclosures.

Only after this offer demonstrates demand, prototype **Tiny Crimes** at $4.99 (costume, prop, authored scenes and a playable variation), then a $6.99 two-pack bundle. These are experiments, not additional products promised or sold by this build. Avoid an all-future-content lifetime offer before content costs are understood.
