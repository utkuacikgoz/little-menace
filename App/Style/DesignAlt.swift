import Foundation

/// Which design option a screen under review shows. Release builds always show A.
/// Screenshot tours pass `-LMAlt B` or `-LMAlt C` (DEBUG only).
enum DesignAlt {
    static var current: String {
        #if DEBUG
        return UserDefaults.standard.string(forKey: "LMAlt") ?? "A"
        #else
        return "A"
        #endif
    }
}
