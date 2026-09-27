import Foundation

public enum Slot: String, Codable, CaseIterable, Sendable {
    case hat, neck, theme, sock, fur
}

public enum ItemSource: Equatable, Sendable {
    case starter
    case level(Int)
    case weeklyGift
    case collection(String) // StoreKit product ID
}

public struct Item: Identifiable, Equatable, Sendable {
    public let id: String
    public let slot: Slot
    public let name: String
    public let source: ItemSource
}

public struct Pack: Identifiable, Equatable, Sendable {
    public let id: String // StoreKit product ID
    public let name: String
    public let itemIDs: [String]
    /// Authored reactions that only play once the collection is owned.
    public let reactionIDs: [String]
    /// Ready-made outfits shown on the collection page.
    public var looks: [Look] = []
}

/// A named outfit: one item per slot it touches.
public struct Look: Identifiable, Equatable, Sendable {
    public var id: String { name }
    public let name: String
    public let itemIDs: [String]
}

public enum Catalog {
    public static let defaultTheme = "tangerine"
    public static let defaultSock = "stripe"

    public static let midnightProductID = "com.belevate.littlemenace.midnight"

    public static let items: [Item] = [
        // Themes: one bold background each.
        Item(id: "tangerine", slot: .theme, name: "Tangerine", source: .starter),
        Item(id: "grape", slot: .theme, name: "Grape", source: .starter),
        Item(id: "pool", slot: .theme, name: "Pool", source: .starter),
        Item(id: "bubblegum", slot: .theme, name: "Bubblegum", source: .level(5)),
        // Socks for sock tug.
        Item(id: "stripe", slot: .sock, name: "Stripe Sock", source: .starter),
        Item(id: "argyle", slot: .sock, name: "Argyle Sock", source: .level(4)),
        // Wearables.
        Item(id: "leaf", slot: .hat, name: "Leaf", source: .level(2)),
        Item(id: "crown", slot: .hat, name: "Paper Crown", source: .weeklyGift),
        Item(id: "bell", slot: .neck, name: "Bell", source: .weeklyGift),
        Item(id: "scarf", slot: .neck, name: "Scarf", source: .level(3)),
        Item(id: "bow", slot: .hat, name: "Bow", source: .weeklyGift),
        // Midnight Snack collection (paid, previewable).
        Item(id: "nightcap", slot: .hat, name: "Nightcap", source: .collection(midnightProductID)),
        Item(id: "moon", slot: .neck, name: "Moon Charm", source: .collection(midnightProductID)),
        Item(id: "midnight", slot: .theme, name: "Midnight", source: .collection(midnightProductID)),
        Item(id: "glow", slot: .sock, name: "Glow Sock", source: .collection(midnightProductID)),
        Item(id: "aurora", slot: .theme, name: "Aurora", source: .collection(midnightProductID)),
        Item(id: "neon", slot: .theme, name: "Neon Night", source: .collection(midnightProductID)),
        Item(id: "galaxy", slot: .theme, name: "Galaxy", source: .collection(midnightProductID)),
        Item(id: "sleepmask", slot: .hat, name: "Sleep Mask", source: .collection(midnightProductID)),
        Item(id: "starclip", slot: .hat, name: "Star Clip", source: .collection(midnightProductID)),
        Item(id: "glowstick", slot: .neck, name: "Glow Stick", source: .collection(midnightProductID)),
        Item(id: "cookiebib", slot: .neck, name: "Cookie Bib", source: .collection(midnightProductID)),
        Item(id: "moonsock", slot: .sock, name: "Moon Sock", source: .collection(midnightProductID)),
        Item(id: "plum", slot: .fur, name: "Plum Fur", source: .collection(midnightProductID)),
        Item(id: "moss", slot: .fur, name: "Moss Fur", source: .collection(midnightProductID)),
        Item(id: "deepsea", slot: .fur, name: "Deep Sea Fur", source: .collection(midnightProductID)),
        Item(id: "cocoa", slot: .fur, name: "Cocoa Fur", source: .collection(midnightProductID)),
    ]

    public static let collections: [Pack] = [
        Pack(id: midnightProductID, name: "Midnight Snack",
             itemIDs: ["nightcap", "moon", "midnight", "glow",
                       "aurora", "neon", "galaxy", "sleepmask", "starclip", "glowstick", "cookiebib", "moonsock",
                       "plum", "moss", "deepsea", "cocoa"],
             reactionIDs: ["fridgeRaid", "moonHowl", "blanketCape"],
             looks: [
                Look(name: "Night Owl", itemIDs: ["nightcap", "moon", "midnight", "deepsea"]),
                Look(name: "Aurora Raid", itemIDs: ["sleepmask", "cookiebib", "aurora", "moss"]),
                Look(name: "Galaxy Brain", itemIDs: ["starclip", "glowstick", "galaxy", "plum"]),
             ]),
    ]

    /// Weekly gifts rotate by ISO week so every player sees the same one in a given week.
    public static let weeklyGiftRotation = ["crown", "bell", "bow"]

    public static func item(_ id: String) -> Item? { items.first { $0.id == id } }
    public static func items(in slot: Slot) -> [Item] { items.filter { $0.slot == slot } }

    public static func isOwned(_ item: Item, state: PetState, entitlements: Set<String>) -> Bool {
        switch item.source {
        case .starter: return true
        case .level(let n): return state.level >= n || state.wardrobe.earned.contains(item.id)
        case .weeklyGift: return state.wardrobe.earned.contains(item.id)
        case .collection(let product): return entitlements.contains(product)
        }
    }

    public static func ownedReactions(entitlements: Set<String>) -> [String] {
        collections.filter { entitlements.contains($0.id) }.flatMap(\.reactionIDs)
    }

    /// Reverts anything equipped that is no longer owned (refund, revocation, reset).
    /// Returns true if anything changed.
    @discardableResult
    public static func sanitize(_ state: inout PetState, entitlements: Set<String>) -> Bool {
        var changed = false
        for slot in Slot.allCases {
            guard let id = state.wardrobe.equipped(slot) else { continue }
            let owned = item(id).map { isOwned($0, state: state, entitlements: entitlements) } ?? false
            if !owned {
                state.wardrobe.equip(nil, in: slot)
                changed = true
            }
        }
        return changed
    }

    /// Items unlocked by reaching exactly `level`.
    public static func unlocks(atLevel level: Int) -> [Item] {
        items.filter { $0.source == .level(level) }
    }
}

public enum OfferPolicy {
    /// The paid collection is shown only after a relationship exists: a few levels and a return visit.
    public static func canShowOffer(_ s: PetState) -> Bool {
        s.level >= Tuning.offerMinLevel && s.counters.visitDays >= Tuning.offerMinVisitDays
    }
}

/// A verified StoreKit transaction reduced to what ownership needs.
public struct TransactionRecord: Equatable, Sendable {
    public var productID: String
    public var revoked: Bool
    public init(productID: String, revoked: Bool) {
        self.productID = productID
        self.revoked = revoked
    }
}

public enum Entitlements {
    /// Non-consumables: owned if any verified, unrevoked transaction exists.
    public static func owned(from records: [TransactionRecord]) -> Set<String> {
        let known = Set(Catalog.collections.map(\.id))
        return Set(records.filter { !$0.revoked && known.contains($0.productID) }.map(\.productID))
    }
}
