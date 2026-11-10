import SwiftUI
import MenaceCore

/// Review S25 (DEBUG only): Settings and Points in the app's cream style instead of stock grey lists.
/// B cream with white rows; C cream with soft tiles like the stamp card; D the same with a live gremlin on top.
/// Release builds draw the stock lists (A).
enum SheetSkin {
    static var option: Character? { ["S25B", "S25C", "S25D"].first(where: Variant.on)?.last }
    static var livingHeader: Bool { option == "D" }
}

extension View {
    /// The whole form: cream page, rounded type, orange controls, a cream navigation bar.
    @ViewBuilder func creamForm() -> some View {
        if SheetSkin.option != nil {
            self.scrollContentBackground(.hidden)
                .background(Ink.eye.ignoresSafeArea())
                .tint(Color(hex: 0xC2541A))
                .fontDesign(.rounded)
                .environment(\.colorScheme, .light)
                .toolbarBackground(Ink.eye, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            self
        }
    }

    /// One section's rows.
    @ViewBuilder func creamSection() -> some View {
        switch SheetSkin.option {
        case nil: self
        case "B": self.listRowBackground(Color.white)
        default: self.listRowBackground(Ink.body.opacity(0.06)).listRowSeparator(.hidden).headerProminence(.increased)
        }
    }
}

/// D: the gremlin at the top of a sheet, reacting to what you do there.
struct SheetGremlin: View {
    @Environment(GameModel.self) private var model
    var reaction: Reaction

    var body: some View {
        VStack(spacing: 6) {
            GremlinView(pose: .pose(for: reaction), hat: model.state.wardrobe.hat, neck: model.state.wardrobe.neck,
                        fur: model.state.wardrobe.fur, size: 120)
            Text(model.state.titleName)
                .font(.system(.title3, design: .rounded).weight(.heavy))
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}
