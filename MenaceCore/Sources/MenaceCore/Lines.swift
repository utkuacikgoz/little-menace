import Foundation

/// The gremlin's rare speech. Short on purpose: the character carries the toy, text only garnishes.
public enum Lines {
    static let table: [Reaction: [String]] = [
        .idle: ["hm.", "…what.", "bored. entertain me.", "I'm plotting nothing.", "snack o'clock?", "hi. again."],
        .attention: ["oh? OH?", "is that for me?", "finger. interesting.", "boop incoming?"],
        .touch: ["hehehe", "again.", "that's the spot", "ticklish. don't tell.", "more. now.", "fine. one more."],
        .feed: ["nom.", "CRUNCH.", "delicious crime.", "mmf!", "more please", "snack acquired."],
        .play: ["game time!", "I'm gonna win.", "ready. set. menace."],
        .sleepy: ["*yawn*", "eyes heavy…", "nap soon?", "sleepy menace."],
        .asleep: ["zzz", "zz…snack…zz", "mm… mine…", "zzz… sock… zzz"],
        .wake: ["I'm back.", "great nap.", "rested. dangerous.", "morning, human."],
        .grumpyWake: ["rude.", "I was dreaming!", "five more minutes.", "grr. hi."],
        .mischief: ["heh.", "who, me?", "worth it.", "no regrets."],
        .refuseFood: ["too full.", "one more and I pop.", "later. belly's busy.", "nope. stuffed."],
        .refuseNap: ["not tired!", "sleep is for later.", "I have plans."],
        .tooSleepy: ["too… sleepy…", "nap first.", "can't. eyelids."],
        .busy: ["hang on.", "one thing at a time."],
        .win: ["WINNER.", "again again!", "too easy.", "I'm the best."],
        .lose: ["rematch.", "you cheated.", "I let you win.", "hmph."],
        .levelUp: ["bigger. badder.", "level up!", "I grew?!"],
        .discovery: ["ooh, new!", "remember that.", "noted."],
    ]

    static let menaceIdle = ["something will fall today.", "I licked it. it's mine.", "trust me.", "chaos is a snack."]
    static let sweetIdle = ["you're my favourite.", "hug? no? hug.", "I saved you a crumb.", "stay a bit?"]

    public static func line<G: RandomNumberGenerator>(for reaction: Reaction, personality: Double, using rng: inout G) -> String? {
        var pool = table[reaction] ?? []
        if reaction == .idle {
            if personality > 0.3 { pool += menaceIdle }
            if personality < -0.3 { pool += sweetIdle }
        }
        return pool.randomElement(using: &rng)
    }

    public static var allLines: [String] {
        table.values.flatMap { $0 } + menaceIdle + sweetIdle
    }
}
