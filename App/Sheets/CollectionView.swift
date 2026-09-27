import SwiftUI
import MenaceCore

/// A quiet, permanent purchase. Previewing never equips or charges anything.
/// Ready-made looks up top, every item below; tapping either dresses the stage.
struct CollectionView: View {
    let collection: Pack
    @Environment(GameModel.self) private var model
    @State private var look: String?
    /// Items tried on after (or instead of) a look, by slot.
    @State private var tried: [Slot: String] = [:]

    private var items: [Item] { collection.itemIDs.compactMap(Catalog.item) }

    private var preview: Wardrobe {
        var value = model.state.wardrobe
        let chosen = collection.looks.first { $0.name == look } ?? collection.looks.first
        for id in chosen?.itemIDs ?? collection.itemIDs {
            if let item = Catalog.item(id) { value.equip(id, in: item.slot) }
        }
        for (slot, id) in tried { value.equip(id, in: slot) }
        return value
    }

    var body: some View {
        let owned = model.entitlements.contains(collection.id)
        let shown = preview
        ScrollViewReader { scroller in
        ScrollView {
            VStack(spacing: 20) {
                CollectionStage(wardrobe: shown)
                VStack(spacing: 4) {
                    Text("Small hours. Big nonsense.")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                    Text("\(collection.itemIDs.count) items · \(collection.reactionIDs.count) reactions")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Ink.body.opacity(0.7))
                }
                if !collection.looks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pick a look").font(.system(.headline, design: .rounded).weight(.heavy))
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(collection.looks) { l in lookCard(l, selected: isSelected(l)) }
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("All \(collection.itemIDs.count) items").font(.system(.headline, design: .rounded).weight(.heavy))
                        .id("items")
                    // Grouped the way the Wardrobe tabs are.
                    ForEach([Slot.fur, .theme, .hat, .neck, .sock], id: \.self) { slot in
                        Text(Self.groupName(slot)).font(.system(.subheadline, design: .rounded).weight(.heavy)).opacity(0.7)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                            ForEach(items.filter { $0.slot == slot }) { item in itemCell(item, on: shown.equipped(item.slot) == item.id) }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Three little performances").font(.system(.headline, design: .rounded).weight(.heavy))
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
                    Button("Wear this look") {
                        for slot in Slot.allCases {
                            guard let id = shown.equipped(slot), collection.itemIDs.contains(id),
                                  let item = Catalog.item(id) else { continue }
                            model.equip(item, in: slot)
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
        #if DEBUG
        .onAppear {
            // Screenshot tours: `-LMPage 1` opens scrolled to the item grid.
            if UserDefaults.standard.integer(forKey: "LMPage") == 1 { scroller.scrollTo("items", anchor: .top) }
        }
        #endif
        }
        .foregroundStyle(Ink.body)
        .background(Ink.eye)
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: shown)
        .onDisappear { model.cancelSpecial() }
        #if DEBUG
        .onAppear {
            // Screenshot tours: `-LMLook 2` starts on the third look.
            let i = UserDefaults.standard.integer(forKey: "LMLook")
            if collection.looks.indices.contains(i) { look = collection.looks[i].name }
        }
        #endif
    }

    private func isSelected(_ l: Look) -> Bool {
        tried.isEmpty && (look ?? collection.looks.first?.name) == l.name
    }

    private static func groupName(_ slot: Slot) -> String {
        switch slot {
        case .fur: return "Fur"
        case .theme: return "Skies"
        case .hat: return "Hats"
        case .neck: return "Neckwear"
        case .sock: return "Tug socks"
        }
    }

    /// A look as a card in the swipeable row.
    private func lookCard(_ l: Look, selected: Bool) -> some View {
        var outfit = model.state.wardrobe
        for id in l.itemIDs { if let item = Catalog.item(id) { outfit.equip(id, in: item.slot) } }
        let names = l.itemIDs.compactMap { Catalog.item($0)?.name }
        return Button {
            look = l.name
            tried = [:]
            model.haptics.play(.tap)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                ZStack {
                    ThemeBackground(themeID: outfit.theme)
                    GremlinView(pose: .idle, hat: outfit.hat, neck: outfit.neck, fur: outfit.fur, size: 110, animated: false)
                }
                .frame(width: 210, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(l.name).font(.system(.headline, design: .rounded).weight(.heavy))
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(names.joined(separator: " · "))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Ink.body.opacity(0.75))
                    .lineLimit(2)
                    .frame(width: 210, alignment: .leading)
            }
            .padding(8)
            .background(Ink.body.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Ink.body, lineWidth: selected ? 3 : 0))
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel("\(l.name): \(names.joined(separator: ", "))")
        .accessibilityHint("Shows this look on the gremlin")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func itemCell(_ item: Item, on: Bool) -> some View {
        Button {
            tried[item.slot] = item.id
            model.haptics.play(.tap)
        } label: {
            VStack(spacing: 4) {
                ItemSwatch(item: item, slot: item.slot)
                    .frame(width: 60, height: 60)
                    .background(Ink.body.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Ink.body, lineWidth: on ? 3 : 0))
                Text(item.name)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .lineLimit(2).multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel("Try on \(item.name)")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// All the parts of a performance stay visible where the user is previewing it.
struct CollectionStage: View {
    let wardrobe: Wardrobe
    @Environment(GameModel.self) private var model

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                GremlinView(pose: model.specialPose ?? .idle, hat: wardrobe.hat, neck: wardrobe.neck, fur: wardrobe.fur, size: 160)
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
