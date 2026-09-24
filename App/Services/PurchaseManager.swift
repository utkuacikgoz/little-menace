import StoreKit
import MenaceCore

/// StoreKit 2 for non-consumable collections. Ownership comes only from verified,
/// unrevoked transactions; nothing is cached server-side because there is no server.
@MainActor
@Observable
final class PurchaseManager {
    enum State: Equatable {
        case idle, purchasing, pending, failed(String), restored
    }

    private(set) var products: [String: Product] = [:]
    private(set) var entitlements: Set<String> = []
    var state: State = .idle
    @ObservationIgnored var onEntitlementsChanged: (@MainActor (Set<String>) -> Void)?

    @ObservationIgnored private var updates: Task<Void, Never>?

    init() {
        updates = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update { await transaction.finish() }
                await self?.refreshEntitlements()
            }
        }
    }

    func loadProducts() async {
        let ids = Catalog.collections.map(\.id)
        do {
            let loaded = try await Product.products(for: ids)
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            // Offline: products stay empty and the wardrobe hides prices. Owned items still work.
        }
    }

    func refreshEntitlements() async {
        var records: [TransactionRecord] = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }
            records.append(TransactionRecord(productID: t.productID, revoked: t.revocationDate != nil))
        }
        let owned = Entitlements.owned(from: records)
        if owned != entitlements {
            entitlements = owned
        }
        onEntitlementsChanged?(owned)
    }

    func purchase(_ productID: String) async {
        guard let product = products[productID] else { return }
        state = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshEntitlements()
                state = .idle
            case .success(.unverified):
                state = .failed("The App Store couldn't verify that purchase.")
            case .pending:
                state = .pending // Ask to Buy or SCA; Transaction.updates delivers it later.
            case .userCancelled:
                state = .idle
            @unknown default:
                state = .idle
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func restore() async {
        state = .purchasing
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            state = .restored
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
