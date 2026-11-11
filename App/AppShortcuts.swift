import AppIntents

/// Siri and Shortcuts: "Feed my gremlin in Little Menace", "Pet Little Menace", "Check on Little Menace".
struct LittleMenaceShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: FeedGremlinIntent(),
                    phrases: ["Feed my gremlin in \(.applicationName)", "Feed \(.applicationName)", "Give \(.applicationName) a snack"],
                    shortTitle: "Feed", systemImageName: "fork.knife")
        AppShortcut(intent: PetGremlinIntent(),
                    phrases: ["Pet my gremlin in \(.applicationName)", "Pet \(.applicationName)"],
                    shortTitle: "Pet", systemImageName: "hand.raised.fill")
        AppShortcut(intent: GremlinStatusIntent(),
                    phrases: ["How is my gremlin in \(.applicationName)", "Check on \(.applicationName)"],
                    shortTitle: "Check On It", systemImageName: "heart.text.square.fill")
    }
}
