import SwiftUI
import MenaceCore

/// This week's stamps, today's challenge, level and discoveries. Icons and numbers only.
struct StampCardView: View {
    @Environment(GameModel.self) private var model
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Something tapped on the card, explained in a bar at the bottom.
    private enum Detail: Equatable { case day(Int), slot(Int), challenge, level, discovery(Discovery) }
    @State private var detail: Detail?

    /// Review options: A current, B labelled, C punch card, D sticker book.
    private var style: Int {
        if Variant.on("S21B") { return 1 }
        if Variant.on("S21C") { return 2 }
        if Variant.on("S21D") { return 3 }
        return 0
    }

    var body: some View {
        Group {
            switch style {
            case 1: labelled
            case 2: punchCard
            case 3: stickerBook
            default: classic
            }
        }
        .foregroundStyle(style == 3 ? Ink.eye : Ink.body)
        .safeAreaInset(edge: .bottom) {
            if style > 0, let detail {
                infoBar(detail)
                    .padding(.horizontal, 16).padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: detail)
        .presentationDetents(style > 0 || dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large]) // big text needs the full height
        .presentationBackground(style == 3 ? Ink.body : Ink.eye)
        #if DEBUG
        .onAppear {
            // Screenshot tours: `-LMPage n` shows discovery n tapped.
            let n = UserDefaults.standard.integer(forKey: "LMPage")
            if style > 0, n > 0, n <= Discovery.allCases.count { detail = .discovery(Discovery.allCases[n - 1]) }
        }
        #endif
    }

    // MARK: Shared

    private var stampCount: Int { model.state.stamps.days.count }
    private var foundCount: Int { Discovery.allCases.filter { model.state.discoveries.contains($0.rawValue) }.count }
    private var challengeProgress: Int {
        let c = model.game.todaysChallenge
        return model.state.challenge.completed ? c.target : min(model.state.challenge.progress, c.target)
    }

    private func tap(_ d: Detail) {
        detail = detail == d ? nil : d
        model.haptics.play(.tap, intensity: 0.5)
    }

    private func info(_ d: Detail) -> (symbol: String, title: String, text: String) {
        let s = model.state
        switch d {
        case .day(let i):
            let name = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][i]
            let today = model.game.days.weekdayIndex(model.now)
            let key = dayKey(offset: i - today)
            if s.stamps.goldDays.contains(key) { return ("star.fill", "\(name): gold stamp", "You played and finished the daily challenge.") }
            if s.stamps.days.contains(key) { return ("pawprint.fill", "\(name): stamped", "You played a round that day.") }
            if i == today { return ("pawprint", "Today", "Play any round to get today's stamp.") }
            if i < today { return ("circle.dashed", "\(name)", "No stamp that day.") }
            return ("calendar", name, "Come back and play to stamp it.")
        case .slot(let n):
            switch n {
            case Tuning.stampsForBonus: return ("sparkles", "Bonus at \(n) stamps", "+\(Tuning.stampMilestoneXP) points when you reach \(n) stamps this week.")
            case Tuning.stampsForGift: return ("gift.fill", "Gift at \(n) stamps", "A free wardrobe item when you reach \(n) stamps this week.")
            case 7: return ("seal.fill", "Full card", "Stamp all 7 days for a discovery.")
            default:
                return n <= stampCount ? ("pawprint.fill", "Stamp \(n)", "One of this week's stamps.") : ("pawprint", "Stamp \(n)", "Play on another day this week to fill it.")
            }
        case .challenge:
            let c = model.game.todaysChallenge
            return (c.symbol, c.spoken, "A new one every day. Finish it for +\(Tuning.challengeXP) points and a gold stamp.")
        case .level:
            return ("arrow.up.circle.fill", "Level \(s.level)", "\(s.pointsToNextLevel) more points to level \(s.level + 1). Levels unlock wardrobe items and never drop.")
        case .discovery(let d):
            return s.discoveries.contains(d.rawValue) ? (d.symbol, d.spoken, "Found!") : ("questionmark", "Not found yet", d.hint)
        }
    }

    private func infoBar(_ d: Detail) -> some View {
        let i = info(d)
        return HStack(spacing: 12) {
            Image(systemName: i.symbol)
                .font(.title3.weight(.bold))
                .frame(width: 44, height: 44)
                .background(Ink.body.opacity(0.08), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(i.title).font(.system(.headline, design: .rounded).weight(.heavy))
                Text(i.text).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Button { detail = nil } label: {
                Image(systemName: "xmark").font(.subheadline.weight(.heavy)).frame(width: 36, height: 36)
            }
            .accessibilityLabel("Close")
        }
        .foregroundStyle(Ink.body)
        .padding(12)
        .background(Color(hex: 0xFFE7B8), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }

    private func dayState(_ i: Int) -> (stamped: Bool, gold: Bool, today: Bool) {
        let today = model.game.days.weekdayIndex(model.now)
        let key = dayKey(offset: i - today)
        return (model.state.stamps.days.contains(key), model.state.stamps.goldDays.contains(key), i == today)
    }

    private static let letters = ["M", "T", "W", "T", "F", "S", "S"]

    // MARK: B: labelled

    private var labelled: some View {
        let s = model.state
        let c = model.game.todaysChallenge
        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header("This week", "\(stampCount) of 7 stamps")
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        let d = dayState(i)
                        Button { tap(.day(i)) } label: {
                            ZStack {
                                Circle().fill(d.stamped ? (d.gold ? Color(hex: 0xFFC83D) : Ink.body) : Ink.body.opacity(0.08))
                                if d.stamped {
                                    Image(systemName: d.gold ? "star.fill" : "pawprint.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(d.gold ? Ink.body : Ink.eye)
                                } else {
                                    Text(Self.letters[i]).font(.system(.headline, design: .rounded).weight(.heavy)).opacity(0.5)
                                }
                                if d.today { Circle().stroke(Ink.body, lineWidth: 3).padding(-4) }
                            }
                            .frame(width: 40, height: 40)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                HStack(spacing: 8) {
                    rewardChip(Tuning.stampsForBonus, "sparkles", "Bonus")
                    rewardChip(Tuning.stampsForGift, "gift.fill", "Gift")
                    rewardChip(7, "seal.fill", "Full card")
                }

                header("Today's challenge", s.challenge.completed ? "Done" : "\(challengeProgress) of \(c.target)").padding(.top, 14)
                Button { tap(.challenge) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: c.symbol).font(.title3.weight(.bold))
                            .frame(width: 48, height: 48).background(Ink.body.opacity(0.08), in: Circle())
                        Text(c.spoken).font(.system(.headline, design: .rounded).weight(.heavy)).multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: s.challenge.completed ? "checkmark.seal.fill" : "info.circle").font(.title3)
                    }
                }

                header("Level \(s.level)", "\(s.pointsToNextLevel) points to level \(s.level + 1)").padding(.top, 14)
                Button { tap(.level) } label: { ProgressView(value: levelProgress(s)).tint(Ink.body) }

                header("Discoveries", "\(foundCount) of \(Discovery.allCases.count)").padding(.top, 14)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(Discovery.allCases, id: \.self) { d in
                        let found = s.discoveries.contains(d.rawValue)
                        Button { tap(.discovery(d)) } label: {
                            Image(systemName: found ? d.symbol : "questionmark")
                                .font(.title3.weight(.bold))
                                .frame(width: 52, height: 52)
                                .background(Ink.body.opacity(found ? 0.14 : 0.05), in: Circle())
                                .overlay(Circle().stroke(Ink.body, lineWidth: detail == .discovery(d) ? 3 : 0))
                                .opacity(found ? 1 : 0.5)
                        }
                        .accessibilityLabel(found ? d.spoken : "Undiscovered. \(d.hint)")
                    }
                }
            }
            .padding(24)
        }
    }

    private func header(_ title: String, _ trailing: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(.title3, design: .rounded).weight(.heavy))
            Spacer()
            Text(trailing).font(.system(.subheadline, design: .rounded).weight(.bold)).opacity(0.65)
        }
    }

    private func rewardChip(_ n: Int, _ symbol: String, _ label: String) -> some View {
        let have = stampCount >= n
        return Button { tap(.slot(n)) } label: {
            HStack(spacing: 5) {
                Image(systemName: symbol)
                Text("\(n) · \(label)").lineLimit(1).minimumScaleFactor(0.8)
            }
            .font(.system(.subheadline, design: .rounded).weight(.heavy))
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Ink.body.opacity(have ? 0.9 : 0.08), in: Capsule())
            .foregroundStyle(have ? Ink.eye : Ink.body)
        }
    }

    // MARK: C: punch card

    private var punchCard: some View {
        let s = model.state
        let c = model.game.todaysChallenge
        let gold = s.stamps.goldDays.count
        return ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("STAMP CARD").font(.system(.caption, design: .rounded).weight(.black)).tracking(1.5)
                        Spacer()
                        Text("\(stampCount)/7").font(.system(.headline, design: .rounded).weight(.black))
                    }
                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { n in
                            Button { tap(.slot(n)) } label: {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Circle().strokeBorder(Ink.body.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                                        if n <= stampCount {
                                            Image(systemName: n <= gold ? "star.fill" : "pawprint.fill")
                                                .font(.system(size: 20, weight: .black))
                                                .foregroundStyle(n <= gold ? Color(hex: 0xE59A2E) : Color(hex: 0xC2541A))
                                                .rotationEffect(.degrees(n % 2 == 0 ? 10 : -12))
                                        }
                                    }
                                    .frame(width: 40, height: 40)
                                    Image(systemName: n == Tuning.stampsForBonus ? "sparkles" : n == Tuning.stampsForGift ? "gift.fill" : n == 7 ? "seal.fill" : "circle.fill")
                                        .font(.caption.weight(.bold))
                                        .opacity(n == Tuning.stampsForBonus || n == Tuning.stampsForGift || n == 7 ? 1 : 0)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(info(.slot(n)).title)
                        }
                    }
                    Text("A stamp for every day you play. Gold when you finish the daily challenge.")
                        .font(.footnote).opacity(0.7)
                }
                .padding(18)
                .background(Color(hex: 0xFFE7B8), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Ink.body.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [6, 4])))
                .rotationEffect(.degrees(-1))

                Button { tap(.challenge) } label: {
                    HStack(spacing: 0) {
                        VStack(spacing: 6) {
                            Text("TODAY").font(.system(.caption2, design: .rounded).weight(.black)).tracking(1)
                            Image(systemName: c.symbol).font(.title2.weight(.bold))
                        }
                        .frame(width: 78).frame(maxHeight: .infinity)
                        .background(Ink.body)
                        .foregroundStyle(Ink.eye)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(c.spoken).font(.system(.headline, design: .rounded).weight(.heavy)).multilineTextAlignment(.leading)
                            Text(s.challenge.completed ? "Done! Gold stamp earned." : "\(challengeProgress) of \(c.target) · +\(Tuning.challengeXP) points")
                                .font(.subheadline).opacity(0.75)
                        }
                        .padding(14)
                        Spacer(minLength: 0)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Ink.body.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button { tap(.level) } label: {
                    VStack(spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Level \(s.level)").font(.system(.title3, design: .rounded).weight(.heavy))
                            Spacer()
                            Text("\(s.pointsToNextLevel) points to level \(s.level + 1)").font(.subheadline.weight(.semibold)).opacity(0.7)
                        }
                        ProgressView(value: levelProgress(s)).tint(Ink.body)
                    }
                }

                HStack {
                    Text("Discoveries").font(.system(.title3, design: .rounded).weight(.heavy))
                    Spacer()
                    Text("\(foundCount) of \(Discovery.allCases.count)").font(.subheadline.weight(.bold)).opacity(0.65)
                }
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                    ForEach(Discovery.allCases, id: \.self) { d in
                        let found = s.discoveries.contains(d.rawValue)
                        Button { tap(.discovery(d)) } label: {
                            HStack(spacing: 10) {
                                Image(systemName: found ? d.symbol : "questionmark")
                                    .font(.headline.weight(.bold))
                                    .frame(width: 38, height: 38)
                                    .background(Ink.body.opacity(found ? 0.14 : 0.05), in: Circle())
                                Text(found ? d.spoken : "???")
                                    .font(.system(.footnote, design: .rounded).weight(.heavy))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                Spacer(minLength: 0)
                            }
                            .padding(8)
                            .background(Ink.body.opacity(detail == .discovery(d) ? 0.14 : 0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .opacity(found ? 1 : 0.6)
                        }
                        .accessibilityLabel(found ? d.spoken : "Undiscovered. \(d.hint)")
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: D: sticker book

    private static let stickerColors = [0xFF7A2F, 0x7B4DFF, 0x14B0E0, 0xFF6FB5, 0x2FBF71, 0x1D2560, 0xE53935, 0xFF8FA3, 0xFFC83D, 0x0F5C63]

    private var stickerBook: some View {
        let s = model.state
        let c = model.game.todaysChallenge
        let next = [Tuning.stampsForBonus, Tuning.stampsForGift, 7].first { $0 > stampCount }
        let nextLabel = next.map { n in "\(n - stampCount) more for \(n == Tuning.stampsForBonus ? "a bonus" : n == Tuning.stampsForGift ? "a gift" : "a full card")" } ?? "Card full!"
        return ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 2) {
                    Text("\(stampCount)/7").font(.system(size: 64, weight: .black, design: .rounded))
                    Text("stamps this week").font(.system(.headline, design: .rounded)).opacity(0.75)
                    Button { tap(.slot(next ?? 7)) } label: {
                        Text(nextLabel)
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(Color(hex: 0xFFD166), in: Capsule())
                            .foregroundStyle(Ink.body)
                    }
                    .padding(.top, 8)
                }

                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        let d = dayState(i)
                        Button { tap(.day(i)) } label: {
                            ZStack {
                                if d.stamped {
                                    Circle().fill(d.gold ? Color(hex: 0xFFC83D) : Color(hex: 0xFF7A2F))
                                        .overlay(Circle().stroke(.white, lineWidth: 3))
                                        .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
                                    Image(systemName: d.gold ? "star.fill" : "pawprint.fill")
                                        .font(.system(size: 17, weight: .black)).foregroundStyle(Ink.body)
                                } else {
                                    Circle().strokeBorder(Ink.eye.opacity(d.today ? 0.9 : 0.3), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                                    Text(Self.letters[i]).font(.system(.headline, design: .rounded).weight(.heavy)).opacity(d.today ? 1 : 0.5)
                                }
                            }
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(d.stamped ? (i % 2 == 0 ? -8 : 8) : 0))
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Button { tap(.challenge) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: c.symbol).font(.title3.weight(.bold))
                            .frame(width: 46, height: 46).background(Ink.body, in: Circle()).foregroundStyle(Color(hex: 0xFFD166))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TODAY'S DARE").font(.system(.caption, design: .rounded).weight(.black)).tracking(1).opacity(0.7)
                            Text(c.spoken).font(.system(.headline, design: .rounded).weight(.heavy)).multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                        Text(s.challenge.completed ? "✓" : "\(challengeProgress)/\(c.target)").font(.system(.title3, design: .rounded).weight(.black))
                    }
                    .padding(14)
                    .background(Color(hex: 0xFFD166), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .foregroundStyle(Ink.body)
                    .rotationEffect(.degrees(-1.5))
                }

                Button { tap(.level) } label: {
                    HStack(spacing: 10) {
                        Text("LEVEL \(s.level)").font(.system(.subheadline, design: .rounded).weight(.black))
                        ProgressView(value: levelProgress(s)).tint(Color(hex: 0xFFD166))
                        Text("\(s.pointsToNextLevel) to go").font(.system(.subheadline, design: .rounded).weight(.bold)).opacity(0.75)
                    }
                }

                HStack {
                    Text("STICKER BOOK").font(.system(.subheadline, design: .rounded).weight(.black)).tracking(1.5)
                    Spacer()
                    Text("\(foundCount)/\(Discovery.allCases.count)").font(.system(.subheadline, design: .rounded).weight(.black))
                }
                .padding(.top, 6)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 18) {
                    ForEach(Array(Discovery.allCases.enumerated()), id: \.element) { i, d in
                        let found = s.discoveries.contains(d.rawValue)
                        Button { tap(.discovery(d)) } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    if found {
                                        Circle().fill(Color(hex: UInt32(Self.stickerColors[i % Self.stickerColors.count])))
                                            .overlay(Circle().stroke(.white, lineWidth: 4))
                                            .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
                                        Image(systemName: d.symbol).font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                                    } else {
                                        Circle().strokeBorder(Ink.eye.opacity(detail == .discovery(d) ? 0.9 : 0.35), style: StrokeStyle(lineWidth: 2.5, dash: [6, 5]))
                                        Image(systemName: "questionmark").font(.system(size: 22, weight: .black)).opacity(0.45)
                                    }
                                }
                                .frame(width: 70, height: 70)
                                .rotationEffect(.degrees(found ? Double((i * 37) % 15) - 7 : 0))
                                Text(found ? d.spoken : "???")
                                    .font(.system(.caption, design: .rounded).weight(.heavy))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .opacity(found ? 1 : 0.5)
                            }
                        }
                        .accessibilityLabel(found ? d.spoken : "Undiscovered. \(d.hint)")
                    }
                }
            }
            .padding(22)
        }
    }

    /// Option A: the current card.
    @ViewBuilder private var classic: some View {
        let s = model.state
        let days = model.game.days
        let today = days.weekdayIndex(model.now)
        let challenge = model.game.todaysChallenge

        ScrollView {
            VStack(spacing: 28) {
                // Week: seven stamps, Monday first. Missed days are just empty.
                HStack(spacing: 6) {
                    ForEach(0..<7, id: \.self) { i in
                        let key = dayKey(offset: i - today)
                        let gold = s.stamps.goldDays.contains(key)
                        let stamped = s.stamps.days.contains(key)
                        let letter = ["M", "T", "W", "T", "F", "S", "S"][i]
                        VStack(spacing: 4) {
                            ZStack {
                                Circle().fill(stamped ? (gold ? Color(hex: 0xFFC83D) : Ink.body) : Ink.body.opacity(0.08))
                                if stamped {
                                    Image(systemName: gold ? "star.fill" : "pawprint.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(gold ? Ink.body : Ink.eye)
                                } else {
                                    Text(letter).font(.system(.headline, design: .rounded).weight(.heavy)).dynamicTypeSize(...DynamicTypeSize.xLarge).opacity(0.5)
                                }
                                if i == today { Circle().stroke(Ink.body, lineWidth: 3).padding(-4) }
                            }
                            .frame(width: 42, height: 42)
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(s.stamps.days.count) of 7 stamps this week. \(Tuning.stampsForBonus) earns a bonus, \(Tuning.stampsForGift) earns a gift.")

                HStack(spacing: 22) {
                    milestone(count: Tuning.stampsForBonus, symbol: "sparkles", have: s.stamps.days.count)
                    milestone(count: Tuning.stampsForGift, symbol: "gift.fill", have: s.stamps.days.count)
                }

                // Today's challenge.
                HStack(spacing: 14) {
                    Image(systemName: challenge.symbol)
                        .font(.title.weight(.bold))
                        .frame(width: 60, height: 60)
                        .background(Ink.body.opacity(0.08), in: Circle())
                    HStack(spacing: 6) {
                        ForEach(0..<challenge.target, id: \.self) { i in
                            Capsule()
                                .fill(i < min(s.challenge.progress, challenge.target) || s.challenge.completed ? Ink.body : Ink.body.opacity(0.12))
                                .frame(width: challenge.target > 3 ? 14 : 30, height: 10)
                        }
                    }
                    if s.challenge.completed {
                        Image(systemName: "checkmark.seal.fill").font(.title2).foregroundStyle(Color(hex: 0x2FBF71))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Today: \(challenge.spoken). \(s.challenge.completed ? "Done" : "\(min(s.challenge.progress, challenge.target)) of \(challenge.target)")")

                // Level.
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("\(s.level)").font(.system(.title2, design: .rounded).weight(.heavy))
                        Spacer()
                        Text("\(s.pointsToNextLevel)").font(.system(.title2, design: .rounded).weight(.heavy))
                        Text("points to Level \(s.level + 1)")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .opacity(0.7)
                    }
                    ProgressView(value: levelProgress(s)).tint(Ink.body)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Level \(s.level). \(s.pointsToNextLevel) more points to level \(s.level + 1).")

                // Discoveries: found ones show their icon, the rest are mysteries.
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                    ForEach(Discovery.allCases, id: \.self) { d in
                        let found = s.discoveries.contains(d.rawValue)
                        Image(systemName: found ? d.symbol : "questionmark")
                            .font(.title3.weight(.bold))
                            .frame(width: 52, height: 52)
                            .background(Ink.body.opacity(found ? 0.12 : 0.04), in: Circle())
                            .opacity(found ? 1 : 0.4)
                            .accessibilityLabel(found ? d.spoken : "Undiscovered")
                    }
                }
            }
            .padding(24)
        }
    }

    private func dayKey(offset: Int) -> String {
        let days = model.game.days
        let date = days.calendar.date(byAdding: .day, value: offset, to: model.now) ?? model.now
        return days.dayKey(date)
    }

    private func milestone(count: Int, symbol: String, have: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
            Text("\(count)").font(.system(.headline, design: .rounded).weight(.heavy))
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Ink.body.opacity(have >= count ? 0.9 : 0.08), in: Capsule())
        .foregroundStyle(have >= count ? Ink.eye : Ink.body)
        .accessibilityHidden(true)
    }

    private func levelProgress(_ s: PetState) -> Double {
        let lo = Tuning.xpForLevel(s.level), hi = Tuning.xpForLevel(s.level + 1)
        return Double(s.xp - lo) / Double(max(1, hi - lo))
    }
}
