import Foundation

/// Versioned save format: `{ "version": N, "state": { … } }` as JSON.
///
/// Adding a field with a sensible default needs no migration (`PetState` decodes leniently).
/// Renaming, restructuring, or adding a field inside a nested struct needs a version bump and
/// a migration step in `SaveCodec.migrations` that rewrites the older JSON dictionary.
public enum SaveCodec {
    public static let currentVersion = 1

    public typealias Migration = (inout [String: Any]) throws -> Void

    /// migrations[n] upgrades a version-n state dictionary to version n+1.
    public static let migrations: [Int: Migration] = [:]

    public enum Failure: Error, Equatable {
        case unreadable
        case futureVersion(Int)
        case missingMigration(Int)
    }

    public static func encode(_ state: PetState) throws -> Data {
        let envelope = Envelope(version: currentVersion, state: state)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(envelope)
    }

    public static func decode(_ data: Data,
                              current: Int = currentVersion,
                              migrations: [Int: Migration] = migrations) throws -> PetState {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var state = root["state"] as? [String: Any]
        else { throw Failure.unreadable }
        var version = root["version"] as? Int ?? 1
        if version > current { throw Failure.futureVersion(version) }
        while version < current {
            guard let step = migrations[version] else { throw Failure.missingMigration(version) }
            try step(&state)
            version += 1
        }
        let migrated = try JSONSerialization.data(withJSONObject: state)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            return try decoder.decode(PetState.self, from: migrated)
        } catch {
            throw Failure.unreadable
        }
    }

    struct Envelope: Encodable {
        let version: Int
        let state: PetState
    }
}

/// Files: `pet.json` (current) and `pet.backup.json` (last good save before it).
/// A save that cannot be read is moved aside, never deleted, and the backup is tried next.
public final class SaveStore: @unchecked Sendable {
    public enum LoadSource: Equatable { case primary, backup, fresh }

    public let directory: URL
    var primary: URL { directory.appendingPathComponent("pet.json") }
    var backup: URL { directory.appendingPathComponent("pet.backup.json") }
    private let fm = FileManager.default

    public init(directory: URL) {
        self.directory = directory
    }

    public static func appDefault() -> SaveStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return SaveStore(directory: base.appendingPathComponent("LittleMenace", isDirectory: true))
    }

    public func load(now: Date) -> (PetState, LoadSource) {
        if let data = try? Data(contentsOf: primary) {
            do {
                return (try SaveCodec.decode(data), .primary)
            } catch {
                quarantine(primary, reason: error)
            }
        }
        if let data = try? Data(contentsOf: backup), let state = try? SaveCodec.decode(data) {
            return (state, .backup)
        }
        return (PetState(now: now), .fresh)
    }

    public func save(_ state: PetState) throws {
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try SaveCodec.encode(state)
        if fm.fileExists(atPath: primary.path) {
            // Only a readable save is promoted to backup.
            if let old = try? Data(contentsOf: primary), (try? SaveCodec.decode(old)) != nil {
                try? old.write(to: backup, options: .atomic)
            }
        }
        try data.write(to: primary, options: .atomic)
    }

    public func wipe() {
        try? fm.removeItem(at: primary)
        try? fm.removeItem(at: backup)
    }

    private func quarantine(_ url: URL, reason: Error) {
        let stamp = Int(Date().timeIntervalSince1970)
        let suffix: String
        if case SaveCodec.Failure.futureVersion(let v) = reason { suffix = "v\(v)" } else { suffix = "bad" }
        let dest = directory.appendingPathComponent("pet.\(suffix).\(stamp).json")
        try? fm.moveItem(at: url, to: dest)
    }
}
