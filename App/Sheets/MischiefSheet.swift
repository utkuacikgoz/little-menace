import SwiftUI
import MenaceCore

/// The gremlin is up to something. One line, two choices, both fine.
struct MischiefSheet: View {
    let event: MischiefEvent
    let choose: (Bool) -> Void
    @Environment(GameModel.self) private var model

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                GremlinView(pose: .pose(for: .mischief), hat: model.state.wardrobe.hat, neck: model.state.wardrobe.neck, size: 96)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: event.prop).font(.title2.weight(.bold))
                        .accessibilityHidden(true)
                    Text(event.line)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 14) {
                choice(event.indulge, indulge: true)
                choice(event.redirect, indulge: false)
            }
        }
        .padding(20)
        .foregroundStyle(Ink.body)
        .presentationBackground(Ink.eye)
    }

    private func choice(_ c: MischiefEvent.Choice, indulge: Bool) -> some View {
        // A: icon only. B: icon and a word. C: tall cards with the word under the icon.
        let word = indulge ? "Let it" : "Stop it"
        return Button { choose(indulge) } label: {
            Group {
                if Alt.b {
                    Label(word, systemImage: c.symbol)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                } else if Alt.c {
                    VStack(spacing: 8) {
                        Image(systemName: c.symbol).font(.largeTitle.weight(.heavy))
                        Text(word).font(.system(.headline, design: .rounded).weight(.heavy))
                    }
                } else {
                    Image(systemName: c.symbol).font(.title.weight(.heavy))
                }
            }
            .frame(maxWidth: .infinity, minHeight: Alt.c ? 120 : 64)
            .background(indulge ? Ink.body : Ink.body.opacity(0.1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .foregroundStyle(indulge ? Ink.eye : Ink.body)
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel(c.spoken)
    }
}
