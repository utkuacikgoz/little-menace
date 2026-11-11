#if DEBUG
import SwiftUI
import WidgetKit
import MenaceCore

/// Design review only (`-LMScreen widgets` / `-LMScreen nap`): the widgets and the nap Live Activity drawn in-app
/// at their real sizes, because a simulator screenshot can't add widgets to the Home Screen.
/// `-LMVariant S28B` (widgets) or `S29B` (nap) picks the option.
struct WidgetGallery: View {
    let page: String
    @Environment(GameModel.self) private var model

    private var widgetLook: WidgetLook {
        let looks: [String: WidgetLook] = ["S28B": .needs, "S28C": .talks, "S28D": .peek]
        return looks.first { Variant.on($0.key) }?.value ?? .portrait
    }

    private var napLook: NapLook {
        let looks: [String: NapLook] = ["S29B": .progress, "S29C": .sign, "S29D": .wakeButton]
        return looks.first { Variant.on($0.key) }?.value ?? .countdown
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x3A2E5C), Color(hex: 0x1B1730)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            if page == "nap" { napPage } else { widgetsPage }
        }
    }

    // MARK: Widgets

    private var widgetsPage: some View {
        let s = model.state
        let line = "my alibi is adorable."
        return VStack(alignment: .leading, spacing: 18) {
            caption("Home Screen")
            HStack(spacing: 22) {
                box(GremlinWidgetView(look: widgetLook, family: .systemSmall, state: s, line: line), w: 158, h: 158, state: s)
                appIcons
            }
            box(GremlinWidgetView(look: widgetLook, family: .systemMedium, state: s, line: line), w: 338, h: 158, state: s)
            caption("Lock Screen")
            HStack(spacing: 14) {
                GremlinWidgetView(look: widgetLook, family: .accessoryCircular, state: s, line: line)
                    .frame(width: 72, height: 72)
                    .background(.white.opacity(0.15), in: Circle())
                GremlinWidgetView(look: widgetLook, family: .accessoryRectangular, state: s, line: line)
                    .frame(width: 170, height: 72, alignment: .leading)
            }
            .foregroundStyle(.white)
            Spacer()
        }
        .padding(24)
        .padding(.top, 30)
    }

    private func box<V: View>(_ view: V, w: CGFloat, h: CGFloat, state: PetState) -> some View {
        view
            .padding(14)
            .frame(width: w, height: h)
            .background(GremlinWidgetBackground(state: state))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var appIcons: some View {
        Grid(horizontalSpacing: 18, verticalSpacing: 18) {
            ForEach(0..<2, id: \.self) { _ in
                GridRow {
                    ForEach(0..<2, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.white.opacity(0.18)).frame(width: 60, height: 60)
                    }
                }
            }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text).font(.system(.footnote, design: .rounded).weight(.heavy)).foregroundStyle(.white.opacity(0.6))
    }

    // MARK: Nap

    private var napPage: some View {
        let s = model.state
        let attributes = NapAttributes(name: s.titleName, hat: s.wardrobe.hat, neck: s.wardrobe.neck, fur: s.wardrobe.fur, theme: s.wardrobe.theme)
        let state = NapAttributes.ContentState(startedAt: Date().addingTimeInterval(-6 * 60), wakesAt: Date().addingTimeInterval(9 * 60))
        return VStack(spacing: 18) {
            HStack(spacing: 10) {
                NapIslandLeading()
                Spacer()
                NapIslandTrailing(state: state)
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .padding(.horizontal, 16)
            .frame(width: 230, height: 37)
            .background(.black, in: Capsule())
            .padding(.top, 2)
            Text("9:41").font(.system(size: 84, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Spacer()
            NapBanner(look: napLook, attributes: attributes, state: state)
                .background(Color(hex: 0x241F33), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 12)
            Spacer().frame(height: 60)
        }
    }
}
#endif
