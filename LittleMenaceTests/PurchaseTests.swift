import XCTest
import StoreKitTest
@testable import LittleMenace

/// Runs inside the app against the local StoreKit configuration. No real money, no network.
@MainActor
final class PurchaseTests: XCTestCase {
    let productID = "app.littlemenace.collection.midnight"
    var session: SKTestSession!

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "LittleMenace")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
    }

    func testProductLoadsWithLocalizedPrice() async {
        let pm = PurchaseManager()
        await pm.loadProducts()
        XCTAssertEqual(pm.products[productID]?.displayPrice.isEmpty, false)
    }

    func testPurchaseGrantsAndRefundRevokes() async throws {
        let pm = PurchaseManager()
        await pm.loadProducts()
        await pm.purchase(productID)
        XCTAssertEqual(pm.state, .idle)
        XCTAssertTrue(pm.entitlements.contains(productID))

        let transaction = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == productID })
        try session.refundTransaction(identifier: transaction.identifier)
        await pm.refreshEntitlements()
        XCTAssertFalse(pm.entitlements.contains(productID), "refund removes ownership")
    }

    func testAskToBuyIsPending() async {
        session.askToBuyEnabled = true
        let pm = PurchaseManager()
        await pm.loadProducts()
        await pm.purchase(productID)
        XCTAssertEqual(pm.state, .pending)
        XCTAssertFalse(pm.entitlements.contains(productID))
    }

    func testFailedPurchaseSurfacesError() async {
        session.failTransactionsEnabled = true
        let pm = PurchaseManager()
        await pm.loadProducts()
        await pm.purchase(productID)
        if case .failed = pm.state {} else { XCTFail("expected failed, got \(pm.state)") }
        XCTAssertFalse(pm.entitlements.contains(productID))
    }

    func testRestoreFindsPriorPurchase() async throws {
        try await session.buyProduct(identifier: productID)
        let pm = PurchaseManager()
        // The sandbox records the purchase asynchronously; give it a few seconds.
        for _ in 0..<30 where !pm.entitlements.contains(productID) {
            await pm.refreshEntitlements()
            if pm.entitlements.contains(productID) { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertTrue(pm.entitlements.contains(productID))
    }
}
