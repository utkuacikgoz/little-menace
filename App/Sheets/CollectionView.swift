import SwiftUI
import MenaceCore

/// Always reachable from Settings, so anyone (including App Review) can preview and buy a
/// collection. The Wardrobe only shows paid items after attachment; this page is the quiet
/// exception, and it is never promoted on the home screen.
struct CollectionView: View {
    let collection: Pack
    @Environment(GameModel.self) private var model

    var body: some View {
        let owned = model.entitlements.contains(collection.id)
        var preview = model.state.wardrobe
        for id in collection.itemIDs {
            if let item = Catalog.item(id), item.slot != .sock { preview.equip(id, in: item.slot) }
        }
        return ScrollView {
            VStack(spacing: 18) {
                ZStack {
                    ThemeBackground(themeID: preview.theme)
                    GremlinView(pose: model.specialPose ?? .pose(for: .mischief), hat: preview.hat, neck: preview.neck, size: 170)
                    if let sock = collection.itemIDs.first(where: { Catalog.item($0)?.slot == .sock }) {
                        SockView(style: sock).scaleEffect(0.45).rotationEffect(.degrees(-20))
                            .frame(width: 50, height: 80).offset(x: 120, y: 60)
                    }
                }
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(model.state.titleName) wearing the \(collection.name) collection")

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(collection.itemIDs, id: \.self) { id in
                        if let item = Catalog.item(id) {
                            Label(item.name, systemImage: symbol(for: item.slot))
                        }
                    }
                }
                .font(.system(.body, design: .rounded).weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

                if owned {
                    Label("Owned. Find it in the Wardrobe.", systemImage: "checkmark.seal.fill")
                        .font(.system(.headline, design: .rounded))
                        .accessibilityIdentifier("owned")
                    reactionButtons
                } else {
                    BuyBar(productID: collection.id)
                }
            }
            .padding(20)
        }
        .foregroundStyle(Ink.body)
        .background(Ink.eye)
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Owners can replay reactions here too (the BuyBar already offers previews otherwise).
    private var reactionButtons: some View {
        HStack(spacing: 10) {
            ForEach(collection.reactionIDs, id: \.self) { id in
                if let special = SpecialReaction.find(id) {
                    Button { model.performSpecial(id) } label: {
                        Image(systemName: special.prop)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(Ink.body.opacity(0.08), in: Capsule())
                    }
                    .accessibilityLabel("Play \(special.name)")
                }
            }
        }
    }

    private func symbol(for slot: Slot) -> String {
        switch slot {
        case .hat: return "crown.fill"
        case .neck: return "bell.fill"
        case .theme: return "paintpalette.fill"
        case .sock: return "hand.draw.fill"
        }
    }
}
