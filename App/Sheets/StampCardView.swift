import SwiftUI
import MenaceCore

/// This week's stamps as a punch card, today's challenge, level and discoveries.
/// Everything is tappable: a bar at the bottom explains what was tapped.
struct StampCardView: View {
    @Environment(GameModel.self) private var model

    /// Something tapped on the card, explained in a bar at the bottom.
    private enum Detail: Equatable { case day(Int), slot(Int), challenge, level, discovery(Discovery) }
    @State private var detail: Detail?

    var body: some View {
        punchCard
            .foregroundStyle(Ink.body)
            .safeAreaInset(edge: .bottom) {
                if let detail {
                    infoBar(detail)
                        .padding(.horizontal, 16).padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: detail)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(Ink.eye)
        #if DEBUG
            .onAppear {
                // Screenshot tours: `-LMPage n` shows discovery n tapped.
                let n = UserDefaults.standard.integer(forKey: "LMPage")
                if n > 0, n <= Discovery.allCases.count { detail = .discovery(Discovery.allCases[n - 1]) }
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
        if detail != nil {
            let i = info(d)
            Announcer.say("\(i.title). \(i.text)")
        }
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
                Image(systemName: "xmark").font(.subheadline.weight(.heavy)).frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close")
        }
        .foregroundStyle(Ink.body)
        .padding(12)
        .background(Color(hex: 0xFFE7B8), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: Card

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
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(stampCount) of 7 stamps this week. \(Tuning.stampsForBonus) earns a bonus, \(Tuning.stampsForGift) earns a gift.")
                    HStack(spacing: 0) {
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
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .contentShape(Rectangle())
                            }
                            .accessibilityLabel(info(.slot(n)).title)
                            .accessibilityValue(n <= stampCount ? (n <= gold ? "Gold stamp" : "Stamped") : "Empty")
                        }
                    }
                    Text("A stamp for every day you play. Gold when you finish the daily challenge.")
                        .font(.footnote).opacity(0.7)
                }
                .padding(.vertical, 18).padding(.horizontal, 14)
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
                                // Not found yet: a nudge in its own voice, enough to chase.
                                Text(found ? d.spoken : d.teaser)
                                    .font(.system(.footnote, design: .rounded).weight(found ? .heavy : .semibold))
                                    .italic(!found)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .padding(8)
                            .background(Ink.body.opacity(detail == .discovery(d) ? 0.14 : 0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                if !found {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(Ink.body.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                }
                            }
                            .opacity(found ? 1 : 0.85)
                        }
                        .accessibilityLabel(found ? d.spoken : "Undiscovered. \(d.teaser) \(d.hint)")
                    }
                }
            }
            .padding(20)
        }
    }

    private func dayKey(offset: Int) -> String {
        let days = model.game.days
        let date = days.calendar.date(byAdding: .day, value: offset, to: model.now) ?? model.now
        return days.dayKey(date)
    }

    private func levelProgress(_ s: PetState) -> Double {
        let lo = Tuning.xpForLevel(s.level), hi = Tuning.xpForLevel(s.level + 1)
        return Double(s.xp - lo) / Double(max(1, hi - lo))
    }
}
