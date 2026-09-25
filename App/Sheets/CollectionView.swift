import SwiftUI
import MenaceCore

/// A quiet, permanent purchase. Previewing never equips or charges anything.
struct CollectionView: View {
    let collection: Pack
    @Environment(GameModel.self) private var model

    private var preview: Wardrobe {
        var value = model.state.wardrobe
        for id in collection.itemIDs {
            if let item = Catalog.item(id) { value.equip(id, in: item.slot) }
        }
        return value
    }

    var body: some View {
        let owned = model.entitlements.contains(collection.id)
        ScrollView {
            VStack(spacing: 20) {
                CollectionStage(wardrobe: preview)
                Text("Small hours. Big nonsense.")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text("A nightcap, moon charm, starry sky, glow sock and three little performances.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                VStack(spacing: 10) {
                    ForEach(collection.reactionIDs, id: \.self) { id in
                        if let special = SpecialReaction.find(id) {
                            Button { model.performSpecial(id) } label: {
                                Label(special.name, systemImage: "play.fill")
                                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .background(Ink.body.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                            }
                            .accessibilityLabel("Preview \(special.name)")
                        }
                    }
                }
                if owned {
                    Label("Yours. For keeps.", systemImage: "checkmark")
                        .accessibilityIdentifier("owned")
                    Button("Wear collection") {
                        for id in collection.itemIDs {
                            if let item = Catalog.item(id) { model.equip(item, in: item.slot) }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Ink.body)
                    .accessibilityIdentifier("wear-collection")
                } else {
                    BuyBar(productID: collection.id, showsReactions: false)
                }
                Button("Restore purchases") { Task { await model.purchases.restore() } }
                    .disabled(model.purchases.state == .purchasing)
                if model.purchases.state == .restored {
                    Text(owned ? "Your collection is restored." : "No collection purchases to restore.")
                        .font(.footnote)
                }
            }
            .padding(20)
        }
        .foregroundStyle(Ink.body)
        .background(Ink.eye)
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { model.cancelSpecial() }
    }
}

/// All the parts of a performance stay visible where the user is previewing it.
struct CollectionStage: View {
    let wardrobe: Wardrobe
    @Environment(GameModel.self) private var model

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                GremlinView(pose: model.specialPose ?? .idle, hat: wardrobe.hat, neck: wardrobe.neck, size: 160)
                if let prop = model.specialProp {
                    Image(systemName: prop)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Ink.eye)
                        .offset(x: -100, y: -25)
                }
                SockView(style: wardrobe.sock).scaleEffect(0.3)
                    .frame(width: 40, height: 50).rotationEffect(.degrees(-15))
                    .offset(x: 95, y: 55)
            }
            .frame(height: 185)
            Text(model.specialLine ?? "Try a little trouble.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Ink.eye)
                .frame(minHeight: 40)
                .accessibilityIdentifier("collection-caption")
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background { ThemeBackground(themeID: wardrobe.theme) }
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
