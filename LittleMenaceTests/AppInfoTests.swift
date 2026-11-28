import XCTest

/// iOS ends the app the moment it touches a privacy-protected feature without saying why.
/// The share sheet's Save Video and Save Image write to Photos, so the app must carry that reason.
final class AppInfoTests: XCTestCase {
    func testSavingToPhotosHasAReason() {
        let reason = Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryAddUsageDescription") as? String
        XCTAssertFalse(reason?.isEmpty ?? true, "Save Video / Save Image would crash without NSPhotoLibraryAddUsageDescription")
    }
}
