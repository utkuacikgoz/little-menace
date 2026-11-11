import Foundation
import MenaceCore

/// One save for the app and its widgets: the shared app group container, so a pet from a widget or Siri
/// and a pet in the app are the same gremlin. The first launch after updating copies the old save across.
enum SharedStore {
    static let groupID = "group.com.belevate.littlemenace"

    static func make() -> SaveStore {
        let legacy = SaveStore.appDefault()
        // No app group (an unsigned build, or the entitlement missing): keep using the app's own folder.
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            return legacy
        }
        let shared = SaveStore(directory: container.appendingPathComponent("LittleMenace", isDirectory: true))
        shared.adoptIfEmpty(from: legacy)
        return shared
    }
}
