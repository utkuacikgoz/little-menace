import SwiftUI
import MenaceCore

/// Owned items equip on tap. Paid items preview on the gremlin first; buying is a separate, explicit tap.
struct WardrobeView: View {
    @Environment(GameModel.self) private var model
    @State private var slot: Slot = .hat
    @State private var preview: Item?

    var body: some View {
        let wardrobe = shownWardrobe
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(ThemePalette.forID(wardrobe.theme).day)
                if slot == .sock {
                    SockView(style: wardrobe.sock).rotationEffect(.degrees(12))
                } else {
                    GremlinView(pose: model.specialPose ?? .pose(for: preview == nil ? .idle : .touch), hat: wardrobe.hat, neck: wardrobe.neck, fur: wardrobe.fur, size: 150)
                }
            }
            .overlay(alignment: .topLeading) {
                if let prop = model.specialProp {
                    Image(systemName: prop).font(.title).foregroundStyle(Ink.eye).padding(20)
                }
            }
            .frame(height: 210)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(previewLabel)
            if preview != nil, let line = model.specialLine {
                Text(line).font(.system(.subheadline, design: .rounded)).multilineTextAlignment(.center)
            }

            HStack(spacing: 10) {
                ForEach(Slot.allCases, id: \.self) { s in
                    Button {
                        slot = s
                        preview = nil
                    } label: {
                        Group {
                            if Variant.on("S5C") {
                                // Option C: icons only; the chosen tab spells out its name.
                                HStack(spacing: 6) {
                                    Image(systemName: symbol(for: s)).font(.title3.weight(.bold))
                                    if slot == s {
                                        Text(slotName(s)).font(.system(.subheadline, design: .rounded).weight(.heavy))
                                            .lineLimit(1).minimumScaleFactor(0.7)
                                    }
                                }
                            } else {
                                VStack(spacing: 2) {
                                    Image(systemName: symbol(for: s))
                                        .font(.title3.weight(.bold))
                                    Text(slotName(s)).font(.system(.caption2, design: .rounded).weight(.heavy))
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                }
                            }
                        }
                            .frame(maxWidth: Variant.on("S5C") && slot != s ? 52 : CGFloat.infinity, minHeight: 56)
                            .background(Ink.body.opacity(slot == s ? 1 : 0.08), in: Capsule())
                            .foregroundStyle(slot == s ? Ink.eye : Ink.body)
                    }
                    .accessibilityLabel(slotName(s))
                    .accessibilityAddTraits(slot == s ? .isSelected : [])
                }
            }

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    if slot == .hat || slot == .neck || slot == .fur {
                        cell(nil)
                    }
                    ForEach(visibleItems) { item in
                        cell(item)
                    }
                }
            }

            if let preview, case .collection(let productID) = preview.source, !model.owns(preview) {
                BuyBar(productID: productID)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(20)
        .foregroundStyle(Ink.body)
        .presentationDetents([.large])
        .presentationBackground(Ink.eye)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: preview)
        .onDisappear { model.cancelSpecial() }
        #if DEBUG
        .onAppear {
            // Screenshot tours: `-LMSlot neck` opens a tab, `-LMPreview nightcap` previews a paid item.
            let d = UserDefaults.standard
            if let raw = d.string(forKey: "LMSlot"), let s = Slot(rawValue: raw) { slot = s }
            if let id = d.string(forKey: "LMPreview"), let item = Catalog.item(id) {
                slot = item.slot
                preview = item
            }
        }
        #endif
    }

    private var visibleItems: [Item] {
        Catalog.items(in: slot).filter { item in
            if case .collection = item.source {
                return model.owns(item) || OfferPolicy.canShowOffer(model.state)
            }
            return true
        }
    }

    private var shownWardrobe: Wardrobe {
        var w = model.state.wardrobe
        if let preview { w.equip(preview.id, in: preview.slot) }
        return w
    }

    private var previewLabel: String {
        let w = shownWardrobe
        let parts = [w.fur, w.hat, w.neck, w.theme].compactMap { $0 }.compactMap { Catalog.item($0)?.name }
        return "\(model.state.titleName) wearing " + (parts.isEmpty ? "nothing" : parts.joined(separator: ", "))
    }

    @ViewBuilder private func cell(_ item: Item?) -> some View {
        let owned = item.map { model.owns($0) } ?? true
        let equipped = model.state.wardrobe.equipped(slot) == item?.id
        let previewing = preview != nil && preview == item
        Button {
            guard let item else {
                preview = nil
                model.equip(nil, in: slot)
                return
            }
            if owned {
                preview = nil
                model.equip(item, in: slot)
            } else if case .collection = item.source {
                preview = item
                model.haptics.play(.tap)
            } else {
                model.haptics.play(.nope)
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                ItemSwatch(item: item, slot: slot)
                    .frame(width: 64, height: 64)
                    .background(Ink.body.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Ink.body, lineWidth: equipped || previewing ? 3 : 0))
                    .opacity(owned || item.map { isPaid($0) } == true ? 1 : 0.7)
                if let item, !owned { lockBadge(item) }
            }
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel(cellLabel(item, owned: owned, equipped: equipped))
    }

    private func isPaid(_ item: Item) -> Bool {
        if case .collection = item.source { return true }
        return false
    }

    @ViewBuilder private func lockBadge(_ item: Item) -> some View {
        Group {
            switch item.source {
            case .level(let n):
                Text("\(n)").font(.system(.caption, design: .rounded).weight(.heavy))
            case .weeklyGift:
                Image(systemName: "gift.fill").font(.caption.weight(.bold))
            case .collection:
                Image(systemName: "sparkles").font(.caption.weight(.bold))
            case .starter:
                EmptyView()
            }
        }
        .frame(width: 24, height: 24)
        .background(Ink.body, in: Circle())
        .foregroundStyle(Ink.eye)
        .offset(x: 6, y: -6)
    }

    private func cellLabel(_ item: Item?, owned: Bool, equipped: Bool) -> String {
        guard let item else {
            let name = slot == .fur ? "Classic fur" : "Nothing"
            return equipped ? "\(name), selected" : name
        }
        var label = item.name
        if equipped { label += ", wearing" }
        if !owned {
            switch item.source {
            case .level(let n): label += ", unlocks at level \(n)"
            case .weeklyGift: label += ", weekly stamp gift"
            case .collection: label += ", in the Midnight Snack collection. Double tap to preview"
            case .starter: break
            }
        }
        return label
    }

    private func symbol(for slot: Slot) -> String {
        switch slot {
        case .hat: return "crown.fill"
        case .neck: return "bell.fill"
        case .theme: return "paintpalette.fill"
        case .sock: return "hand.draw.fill"
        case .fur: return "pawprint.fill"
        }
    }

    private func slotName(_ slot: Slot) -> String {
        switch slot {
        case .hat: return "Hats"
        case .neck: return "Neckwear"
        case .theme: return Variant.on("S5B") ? "Skies" : "Backgrounds"
        case .sock: return "Tug socks"
        case .fur: return "Fur"
        }
    }
}

/// One item drawn small enough for a 64-point cell. `item == nil` is the "take it off" cell
/// (or the classic coat, on the fur tab).
struct ItemSwatch: View {
    let item: Item?
    var slot: Slot

    init(item: Item?, slot: Slot) {
        self.item = item
        self.slot = item?.slot ?? slot
    }

    var body: some View {
        if let item {
            switch item.slot {
            case .theme:
                Circle().fill(ThemePalette.forID(item.id).day)
                    .overlay(Circle().fill(RadialGradient(colors: [ThemePalette.forID(item.id).glow.opacity(0.6), .clear], center: .center, startRadius: 2, endRadius: 22)))
                    .frame(width: 40, height: 40)
            case .sock:
                SockView(style: item.id).scaleEffect(0.35).frame(width: 40, height: 50)
            // Wearables draw in the 200×220 gremlin space; move the item to the centre, then shrink it to fit.
            case .hat:
                Wearables(hat: item.id, neck: nil).offset(y: 110 - 46).scaleEffect(0.55).frame(width: 60, height: 60).clipped()
            case .neck:
                Wearables(hat: nil, neck: item.id).offset(y: 110 - 158).scaleEffect(0.45).frame(width: 60, height: 60).clipped()
            case .fur:
                coat(item.id)
            }
        } else if slot == .fur {
            coat(nil)
        } else {
            Image(systemName: "circle.slash").font(.title2.weight(.bold))
        }
    }

    @ViewBuilder private func coat(_ id: String?) -> some View {
        if Variant.on("S6B") {
            // Option B: a plain colour dot.
            let c = FurPalette.forID(id)
            Circle().fill(RadialGradient(colors: [c.light, c.body, c.dark], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 2, endRadius: 26))
                .frame(width: 40, height: 40)
        } else if Variant.on("S6C") {
            // Option C: a bigger gremlin, cropped to the head.
            GremlinView(pose: .idle, fur: id, size: 84, animated: false)
                .offset(y: 6)
                .frame(width: 60, height: 60, alignment: .top)
                .clipped()
        } else {
            GremlinView(pose: .idle, fur: id, size: 46, animated: false)
        }
    }
}

struct BuyBar: View {
    let productID: String
    var showsReactions = true
    @Environment(GameModel.self) private var model

    var body: some View {
        let collection = Catalog.collections.first { $0.id == productID }
        let product = model.purchases.products[productID]
        VStack(spacing: 10) {
            HStack {
                Text(collection?.name ?? "Collection")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                Spacer()
                Text("\(collection?.itemIDs.count ?? 0) items")
                    .font(.subheadline)
                    .foregroundStyle(Ink.body.opacity(0.7))
            }
            // Reactions are previewable too: tap to watch the gremlin do it.
            if showsReactions {
            HStack(spacing: 10) {
                ForEach(collection?.reactionIDs ?? [], id: \.self) { id in
                    if let special = SpecialReaction.find(id) {
                        Button { model.performSpecial(id) } label: {
                            Image(systemName: special.prop)
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background(Ink.body.opacity(0.08), in: Capsule())
                        }
                        .accessibilityLabel("Preview \(special.name)")
                    }
                }
            }
            }
            Text("One purchase. Yours to keep.")
                .font(.footnote)
            Button {
                Task { await model.purchases.purchase(productID) }
            } label: {
                Group {
                    switch model.purchases.state {
                    case .purchasing: ProgressView().tint(Ink.eye)
                    case .pending: Text("Waiting for approval")
                    default: Text(product.map { "Buy for \($0.displayPrice)" } ?? (model.purchases.isLoadingProducts ? "Loading price…" : "Store unavailable"))
                    }
                }
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Ink.body, in: Capsule())
                .foregroundStyle(Ink.eye)
            }
            .disabled(product == nil || model.purchases.state == .purchasing || model.purchases.state == .pending)
            .accessibilityIdentifier("buy")
            .accessibilityLabel(product.map { "Buy \(collection?.name ?? "") for \($0.displayPrice)" } ?? "Store unavailable")

            if product == nil && !model.purchases.isLoadingProducts {
                Text("You can still preview everything.").font(.footnote)
                Button("Try store again") { Task { await model.purchases.loadProducts() } }
                    .frame(minHeight: 44)
            }
            if case .failed(let message) = model.purchases.state {
                Text(message).font(.footnote).foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(Ink.body.opacity(0.06), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
