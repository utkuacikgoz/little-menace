import Foundation

/// Authored, local dialogue. Never requires an account or a generation service.
public enum Lines {
    public static let historyLimit = 50

    static let table: [Reaction: [String]] = [
        .idle: [
            "hm.", "…what.", "bored. entertain me.", "I'm plotting nothing.",
            "hi. again.", "this floor is mine.", "suspiciously quiet in here.",
            "I have a tiny agenda.", "don't check the pockets.", "excellent ceiling.",
            "I could eat a button.", "no thoughts. one scheme.", "I heard a wrapper.",
            "I've rearranged the air.", "being small is a full-time job.", "you saw nothing.",
            "thinking with my ears.", "the furniture started it.", "I have indoor zoomies.",
            "my alibi is adorable.", "I live here now.", "this is my good side. both.",
            "please admire the feet.", "a perfectly normal creature.",
        ],
        .attention: [
            "oh? OH?", "is that for me?", "finger. interesting.", "boop incoming?",
            "I see that.", "hold it right there.", "eyes on the prize.", "closer. suspiciously closer.",
            "what have you got?", "tiny inspection underway.", "mine?", "ears are listening.",
        ],
        .touch: [
            "hehehe", "again.", "that's the spot", "ticklish. don't tell.", "more. now.",
            "fine. one more.", "I accept this tribute.", "ears first, please.", "oh. that's nice.",
            "softness is a strategy.", "you may continue.", "my one weakness. head pats.",
            "I wasn't purring.", "a very good hand.", "do the other ear.", "I'm keeping you.",
        ],
        .feed: [
            "nom.", "CRUNCH.", "delicious crime.", "mmf!", "snack acquired.", "for quality control.",
            "gone. mysterious.", "compliments to the cupboard.", "crumbs are a food group.",
            "I ate the evidence.", "a little less dignified now.", "belly says thank you.",
            "that hit the spot.", "one for me. none for gravity.", "chef's tiny kiss.", "worth the crumbs.",
        ],
        .play: [
            "game time!", "I'm gonna win.", "ready. set. menace.", "watch the feet.",
            "warm-up wiggle.", "no rules about being cute.", "serious game face.", "oh, you're on.",
            "a worthy opponent.", "prepare for small chaos.", "socks at dawn.", "I trained for eleven seconds.",
        ],
        .sleepy: [
            "*yawn*", "eyes heavy…", "nap soon?", "sleepy menace.", "blinking takes ages now.",
            "my ears are on low power.", "one eyelid at a time.", "the floor looks comfy.",
            "saving my schemes for later.", "a small lie-down, perhaps.", "running on crumbs.", "yawn. excuse my fang.",
        ],
        .asleep: [
            "zzz", "zz…snack…zz", "mm… mine…", "zzz… sock… zzz", "dreaming in crumbs.",
            "tiny snore. enormous dream.", "off-duty menace.", "five imaginary snacks.",
            "shh. important nap.", "zz… caught it…", "the sock can wait.", "do not disturb the fluff.",
            "chasing a very slow biscuit.", "ears off. dreams on.", "mm… blanket…", "zz… no witnesses…",
        ],
        .wake: [
            "I'm back.", "great nap.", "rested. dangerous.", "morning, human.", "where did I put my legs?",
            "dream snack wasn't real. rude.", "all systems fluffy.", "I slept on my scheme.",
            "new nap. same menace.", "a little stretch first.", "the ceiling is still there.", "ready for mild trouble.",
        ],
        .grumpyWake: [
            "rude.", "I was dreaming!", "five more minutes.", "grr. hi.", "I almost caught the biscuit.",
            "my eyes aren't dressed yet.", "who scheduled this?", "I'm awake in instalments.",
            "one ear is still asleep.", "was it something crunchy?", "fine. but slowly.", "I was on a dream break.",
        ],
        .mischief: [
            "heh.", "who, me?", "worth it.", "no regrets.", "an artistic decision.", "it was like that already.",
            "I improved it.", "technically, it still works.", "a tiny misunderstanding.", "I had my reasons.",
            "the paw prints prove nothing.", "consider it redecorated.", "a victim of curiosity.", "oops is a complete sentence.",
            "I meant to do most of that.", "lovely day for an alibi.",
        ],
        .refuseFood: [
            "too full.", "one more and I pop.", "later. belly's busy.", "nope. stuffed.", "no room at the inn.",
            "please ask the belly later.", "my snack shelf is full.", "saving that for later.",
            "eyes say yes. belly says no.", "maximum biscuit reached.", "I need a digestion break.", "even I have limits.",
            "snack queue is closed.", "not a crumb more.", "currently shaped like lunch.", "a pat would fit, though.",
        ],
        .refuseNap: [
            "not tired!", "sleep is for later.", "I have plans.", "still got wiggles.", "nap tank: full.",
            "my eyelids disagree.", "too awake for a blanket.", "I just charged these feet.",
            "the zoomies haven't left.", "can we play instead?", "I have important standing.", "ask me after some mischief.",
        ],
        .tooSleepy: [
            "too… sleepy…", "nap first.", "can't. eyelids.", "the sock wins this round.",
            "my paws have clocked out.", "a nap, then a rematch.", "too tired to be dramatic.", "saving the zoomies.",
            "brain says play. feet say nap.", "let me recharge my nonsense.", "a little rest will do it.", "sleepy is a whole mood.",
        ],
        .busy: [
            "hang on.", "one thing at a time.", "paws are occupied.", "let me finish this bit.",
            "tiny queue forming.", "currently very involved.", "just a little moment.", "only two paws, you know.",
            "still doing the first thing.", "one scheme at a time.", "hold that thought.", "nearly. probably.",
        ],
        .win: [
            "WINNER.", "again again!", "too easy.", "I'm the best.", "victory wiggle.", "entirely planned.",
            "did you see the technique?", "a trophy would suit me.", "I would like a tiny podium.",
            "tell the cushions.", "small paws. big result.", "put that in my scrapbook.",
        ],
        .lose: [
            "rematch.", "you cheated.", "I let you win.", "hmph.", "a rehearsal, obviously.", "the floor moved.",
            "I demand a softer opponent.", "best of approximately ten?", "losing builds fluff.",
            "my strategy was decorative.", "an educational disaster.", "next time. tiny promise.",
        ],
        .levelUp: [
            "bigger. badder.", "level up!", "I grew?!", "new level. same feet.", "professionally small now.",
            "experience looks good on me.", "promoted to senior menace.", "I learned absolutely enough.",
            "a little more legendary.", "my ears feel qualified.", "please update my tiny badge.", "still fits in your phone.",
        ],
        .discovery: [
            "ooh, new!", "remember that.", "noted.", "well, that's going in the book.", "a first for these paws.",
            "I didn't know I could do that.", "small discovery. big ears.", "one more tiny secret.",
            "we found a thing.", "I shall act surprised again.", "interesting. suspiciously so.", "a new reason to wiggle.",
        ],
    ]

    static let contexts: [String: [String]] = [
        "hungry": ["a snack-shaped gap in my day.", "checking the biscuit forecast.", "belly has a suggestion.", "anything crunchy nearby?", "I can hear the cupboard.", "could investigate a cookie.", "snack thoughts. only snacks.", "my lunch has gone missing."],
        "morning": ["morning hair. all of it.", "first scheme of the day.", "is breakfast a hobby?", "the sun is being loud.", "good morning to my feet.", "a fresh day to be suspicious.", "woke up this small.", "early bird gets my crumbs."],
        "night": ["the moon looks like a snack.", "after-hours nonsense.", "night shift. tiny staff.", "the stars know nothing.", "quiet paws. loud thoughts.", "a respectable bedtime crime.", "moonlight suits my ears.", "just checking on the dark."],
        "menace": ["something will fall today.", "I licked it. it's mine.", "trust me.", "chaos is a snack.", "the spoons have unionised.", "I have a cupboard to inspect.", "a small, suspicious shuffle.", "my plans have little legs."],
        "sweet": ["you're my favourite.", "hug? no? hug.", "I saved you a crumb.", "stay a bit?", "a soft spot. for you.", "we make a good little team.", "I kept this corner warm.", "your hand is my favourite."],
        "tugMemory": ["still thinking about that sock.", "the sock and I have history.", "my grip is mostly confidence.", "a rematch lives in my heart.", "I've been studying the sock.", "tug champion. self-appointed.", "we should consult the sock.", "that sock knows my technique."],
        "snackMemory": ["catching snacks is a career.", "I've developed snack reflexes.", "still a biscuit athlete.", "I dream in little snack arcs.", "those catches were delicious.", "practising my victory chew.", "catch first. questions later.", "my mouth has excellent aim."],
        "huntMemory": ["the cushions know too much.", "my hiding spot is classified.", "we meet again, cushions.", "I was perfectly camouflaged.", "next time, hide the ears.", "a master of almost invisible.", "cushion three looks nervous.", "my tail gave nothing away."],
        "outfit": ["I chose to look this good.", "an outfit with intentions.", "dressed for minor trouble.", "do my ears look expensive?", "a very important little look.", "fashion has paws now.", "don't wrinkle my confidence.", "same menace. new silhouette."],
        "return": ["oh, it's you. excellent.", "I kept the floor company.", "welcome back to my nonsense.", "right where we left our paws.", "you arrived at a good wiggle.", "I have acquired no wisdom.", "another day. still tiny.", "our little routine. I like it."],
    ]

    /// Urgent states never borrow cheerful or food-seeking idle lines.
    static func pool(for reaction: Reaction, state: PetState, hour: Int) -> [String] {
        guard reaction == .idle else { return table[reaction] ?? [] }
        if state.isAsleep { return table[.asleep] ?? [] }
        if state.needs.energy < 30 { return table[.sleepy] ?? [] }
        if state.needs.fullness < 35 { return contexts["hungry"] ?? [] }
        var pool = table[.idle] ?? []
        if hour < 5 || hour >= 21 { pool += contexts["night"] ?? [] }
        else if hour < 11 { pool += contexts["morning"] ?? [] }
        if state.personality > 0.3 { pool += contexts["menace"] ?? [] }
        if state.personality < -0.3 { pool += contexts["sweet"] ?? [] }
        if state.counters.rounds(.sockTug) > 0 { pool += contexts["tugMemory"] ?? [] }
        if state.counters.rounds(.snackToss) > 0 { pool += contexts["snackMemory"] ?? [] }
        if state.counters.rounds(.cushionHunt) > 0 { pool += contexts["huntMemory"] ?? [] }
        if state.wardrobe.hat != nil || state.wardrobe.neck != nil { pool += contexts["outfit"] ?? [] }
        if state.counters.visitDays > 1 { pool += contexts["return"] ?? [] }
        if state.needs.fullness >= Tuning.refuseFoodAt {
            pool.removeAll { ["I could eat a button.", "I heard a wrapper.", "is breakfast a hobby?", "the moon looks like a snack."].contains($0) }
        }
        return pool
    }

    /// Excludes the last 50 utterances. Small pools cycle oldest-first when exhausted.
    /// Saving the history alongside the pet prevents relaunch from restarting its voice.
    public static func next<G: RandomNumberGenerator>(for reaction: Reaction, state: inout PetState, hour: Int, using rng: inout G) -> String? {
        let pool = pool(for: reaction, state: state, hour: hour)
        let unseen = pool.filter { !state.recentLines.contains($0) }
        let line = unseen.randomElement(using: &rng) ?? state.recentLines.first(where: pool.contains)
        guard let line else { return nil }
        state.recentLines.removeAll { $0 == line }
        state.recentLines.append(line)
        state.recentLines = Array(state.recentLines.suffix(historyLimit))
        return line
    }

    public static var allLines: [String] { table.values.flatMap { $0 } + contexts.values.flatMap { $0 } }
}
