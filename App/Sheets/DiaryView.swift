import SwiftUI
import MenaceCore

/// The last week, a line a day in its voice, under a shareable rap sheet of its crimes.
struct DiaryView: View {
    @Environment(GameModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var card: Image?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 14) {
                        RapSheetCard(state: model.state)
                            .scaleEffect(0.62)
                            .frame(width: 360 * 0.62, height: 450 * 0.62)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        if let card {
                            ShareLink(item: card, preview: SharePreview("\(model.state.titleName)'s rap sheet", image: card)) {
                                Label("Share the rap sheet", systemImage: "square.and.arrow.up")
                                    .font(.system(.headline, design: .rounded).weight(.heavy))
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(Ink.body, in: Capsule())
                                    .foregroundStyle(Ink.eye)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .creamSection()
                Section("This week") {
                    if model.state.diary.isEmpty {
                        Text("nothing written yet. give it a day.").foregroundStyle(.secondary)
                    }
                    ForEach(model.state.diary.reversed(), id: \.day) { day in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(weekday(day.day)).font(.system(.subheadline, design: .rounded).weight(.heavy))
                            Text(Diary.line(day, name: model.state.titleName)).font(.system(.body, design: .rounded))
                        }
                        .padding(.vertical, 4)
                        .accessibilityElement(children: .combine)
                    }
                }
                .creamSection()
            }
            .creamForm()
            .navigationTitle("\(model.state.titleName)'s diary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { renderCard() }
        }
    }

    private func weekday(_ key: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: key) else { return key }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.wide))
    }

    private func renderCard() {
        let renderer = ImageRenderer(content: RapSheetCard(state: model.state))
        renderer.scale = 3
        if let ui = renderer.uiImage { card = Image(uiImage: ui) }
    }
}

/// A mugshot against a height chart, with its record. Rendered for sharing at 1080 × 1350.
struct RapSheetCard: View {
    let state: PetState

    var body: some View {
        let sheet = state.rapSheet
        VStack(spacing: 0) {
            ZStack {
                Color(hex: 0xE9E4D8)
                VStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { i in
                        HStack {
                            Text("\(6 - i)").font(.system(size: 13, weight: .heavy, design: .monospaced))
                            Rectangle().frame(height: 2)
                            Text("\(6 - i)").font(.system(size: 13, weight: .heavy, design: .monospaced))
                        }
                        .foregroundStyle(Color(hex: 0x6B6458))
                        .frame(maxHeight: .infinity)
                    }
                }
                .padding(.horizontal, 14)
                GremlinView(pose: Self.pose, hat: state.wardrobe.hat, neck: state.wardrobe.neck, fur: state.wardrobe.fur,
                            size: 150, animated: false)
                    .offset(y: 12)
                Text("LITTLE MENACE PD")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: 0x6B6458))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 8)
            }
            .frame(height: 245)
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(state.titleName.uppercased()).font(.system(size: 22, weight: .black, design: .rounded))
                    Spacer()
                    Text("No. \(String(format: "%05d", 10_000 + state.xp % 90_000))")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                }
                Divider().overlay(Ink.eye.opacity(0.4))
                row("Mischief", sheet.totalMischief)
                row("Snacks refused", sheet.snacksRefused)
                row("Pokes resented", sheet.pokesResented)
                row("Threw up on purpose", sheet.pukes)
                if let top = sheet.mischief.max(by: { $0.value < $1.value }), let e = MischiefBook.event(top.key) {
                    Text("Known for: “\(e.line)”")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .opacity(0.85)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Text("Little Menace").font(.system(size: 12, weight: .bold, design: .rounded)).opacity(0.6)
            }
            .foregroundStyle(Ink.eye)
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Ink.body)
        }
        .frame(width: 360, height: 450)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rap sheet for \(state.titleName): \(sheet.totalMischief) mischief, \(sheet.snacksRefused) snacks refused, \(sheet.pokesResented) pokes resented.")
    }

    private func row(_ label: String, _ n: Int) -> some View {
        HStack {
            Text(label).font(.system(size: 15, weight: .bold, design: .rounded))
            Spacer()
            Text("\(n)").font(.system(size: 17, weight: .black, design: .rounded)).monospacedDigit()
        }
    }

    /// Unimpressed, looking straight at the camera.
    static var pose: GremlinPose {
        var p = GremlinPose()
        p.browTilt = 8; p.mouthSmile = -0.2; p.eyeOpen = 0.85; p.browAsym = 1
        return p
    }
}
