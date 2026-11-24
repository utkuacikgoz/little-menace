import Foundation

/// One day of what happened, for the diary. Only counts and mischief ids: nothing personal.
public struct DiaryDay: Codable, Equatable, Sendable {
    public var day: String
    public var feeds = 0
    public var pets = 0
    public var naps = 0
    public var rounds = 0
    public var wins = 0
    public var pokes = 0
    public var pukes = 0
    public var refusals = 0
    /// Mischief events resolved that day, and whether each was indulged.
    public var mischief: [String] = []
    public var indulged = 0

    public init(day: String) { self.day = day }
}

/// Lifetime offences, for the rap sheet.
public struct RapSheet: Codable, Equatable, Sendable {
    public var pokesResented = 0
    public var snacksRefused = 0
    public var pukes = 0
    public var mischief: [String: Int] = [:]
    public var indulged = 0

    public init() {}

    public var totalMischief: Int { mischief.values.reduce(0, +) }
}

public enum Diary {
    /// Days kept in the diary.
    public static let daysKept = 7

    /// One line per day, in its own voice. Days with nothing in them say so.
    public static func line(_ d: DiaryDay, name: String) -> String {
        var bits: [String] = []
        if d.feeds > 0 { bits.append(d.feeds == 1 ? "ate a snack" : "ate \(d.feeds) snacks") }
        if d.refusals > 0 { bits.append("refused \(d.refusals) more") }
        if d.pukes > 0 { bits.append("threw up. not sorry") }
        if d.rounds > 0 { bits.append(d.wins == d.rounds ? "won every game (\(d.wins))" : "won \(d.wins) of \(d.rounds) games") }
        if d.pets > 0 { bits.append(d.pets == 1 ? "allowed one pet" : "allowed \(d.pets) pets") }
        if d.pokes > 0 { bits.append("got poked too much") }
        if d.naps > 0 { bits.append(d.naps == 1 ? "napped" : "napped \(d.naps) times") }
        for id in d.mischief.prefix(2) {
            if let e = MischiefBook.event(id) { bits.append(e.line.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))) }
        }
        guard !bits.isEmpty else { return "nothing happened. suspicious." }
        let joined = bits.count == 1 ? bits[0] : bits.dropLast().joined(separator: ", ") + " and " + bits[bits.count - 1]
        return joined.prefix(1).uppercased() + joined.dropFirst() + "."
    }
}

extension Game {
    /// Adds to today's diary entry, keeping the last week.
    mutating func logDay(_ now: Date, _ edit: (inout DiaryDay) -> Void) {
        let key = days.dayKey(now)
        if state.diary.last?.day != key { state.diary.append(DiaryDay(day: key)) }
        edit(&state.diary[state.diary.count - 1])
        if state.diary.count > Diary.daysKept { state.diary.removeFirst(state.diary.count - Diary.daysKept) }
    }
}
