import SwiftUI
import MenaceCore

/// A card rendered from the player's actual the gremlin (theme, outfit, level, week, mood),
/// handed to the system share sheet. Nothing is posted automatically.
struct ShareCardView: View {
    let state: PetState
    let pose: GremlinPose
    /// Review S34 B–D: its latest line in a bubble over its head.
    var line: String? = nil
    /// A moment on the timeline, for one frame of the moving card.
    var time: Double? = nil

    var body: some View {
        let palette = ThemePalette.forID(state.wardrobe.theme)
        ZStack {
            palette.day
            RadialGradient(colors: [palette.glow.opacity(0.6), .clear], center: .init(x: 0.5, y: 0.45), startRadius: 10, endRadius: 260)
            VStack(spacing: 10) {
                Spacer(minLength: 12)
                if let line {
                    CardBubble(text: line, time: time)
                }
                GremlinView(pose: pose, hat: state.wardrobe.hat, neck: state.wardrobe.neck, fur: state.wardrobe.fur, size: line == nil ? 170 : 140,
                            animated: false, frameTime: time.map { 1000 + $0 })
                Text(state.titleName)
                    .font(.system(size: 40, weight: .black, design: .rounded))
                Text(Self.title(for: state.personality))
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .opacity(0.85)
                // The score is the brag: same dark pill and gold star as the home scoreboard.
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "star.fill").foregroundStyle(Ink.irisLight)
                    Text(state.points.total, format: .number).monospacedDigit()
                    Text("points").font(.system(size: 16, weight: .heavy, design: .rounded)).opacity(0.85)
                }
                .font(.system(size: 26, weight: .black, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Ink.body.opacity(0.85), in: Capsule())
                HStack(spacing: 18) {
                    Label("\(state.level)", systemImage: "arrow.up.circle.fill")
                    Label("\(state.stamps.days.count)/7", systemImage: "seal.fill")
                    Label("\(state.discoveries.count)", systemImage: "sparkles")
                }
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                Spacer(minLength: 6)
                Text("Little Menace")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .opacity(0.7)
                    .padding(.bottom, 14)
            }
            .foregroundStyle(.white)
        }
        .frame(width: 360, height: 450)
    }

    static func title(for personality: Double) -> String {
        if personality > 0.3 { return "certified menace" }
        if personality < -0.3 { return "secret softie" }
        return "chaotic little gremlin"
    }
}

/// Review S34 (DEBUG only): A today's card; B the card with its latest line; C B as a looping video;
/// D a full-screen 9:16 video for TikTok and Stories.
enum ShareLook {
    static var level: Int {
        Variant.on("S34D") ? 3 : Variant.on("S34C") ? 2 : Variant.on("S34B") ? 1 : 0
    }
    static var moving: Bool { level >= 2 }
}

/// A speech bubble that pops in after a beat on the moving cards.
struct CardBubble: View {
    let text: String
    var time: Double?
    var big = false

    var body: some View {
        let shown = time.map { min(1, max(0, ($0 - 0.5) / 0.25)) } ?? 1
        Text(text)
            .font(.system(size: big ? 30 : 19, weight: .heavy, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundStyle(Ink.body)
            .padding(.horizontal, big ? 22 : 14).padding(.vertical, big ? 14 : 9)
            .background(Ink.eye, in: RoundedRectangle(cornerRadius: big ? 22 : 16, style: .continuous))
            .padding(.horizontal, 20)
            .scaleEffect(0.6 + 0.4 * shown)
            .opacity(shown)
    }
}

/// D: a tall card for TikTok and Stories.
struct StoryCardView: View {
    let state: PetState
    let pose: GremlinPose
    let line: String
    var time: Double?

    var body: some View {
        let palette = ThemePalette.forID(state.wardrobe.theme)
        ZStack {
            palette.day
            RadialGradient(colors: [palette.glow.opacity(0.7), .clear], center: .init(x: 0.5, y: 0.5), startRadius: 10, endRadius: 380)
            VStack(spacing: 16) {
                Spacer(minLength: 40)
                CardBubble(text: line, time: time, big: true)
                GremlinView(pose: pose, hat: state.wardrobe.hat, neck: state.wardrobe.neck, fur: state.wardrobe.fur, size: 250,
                            animated: false, frameTime: time.map { 1000 + $0 })
                Text(state.titleName).font(.system(size: 50, weight: .black, design: .rounded))
                Text(ShareCardView.title(for: state.personality)).font(.system(size: 22, weight: .heavy, design: .rounded)).opacity(0.85)
                HStack(spacing: 20) {
                    Label("\(state.level)", systemImage: "arrow.up.circle.fill")
                    Label("\(state.rapSheet.totalMischief)", systemImage: "exclamationmark.triangle.fill")
                    Label("\(state.points.total)", systemImage: "star.fill")
                }
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                Spacer()
                Text("littlemenace.fun").font(.system(size: 18, weight: .heavy, design: .rounded)).opacity(0.8).padding(.bottom, 40)
            }
            .foregroundStyle(.white)
        }
        .frame(width: 360, height: 640)
    }
}

struct ShareCardSheet: View {
    @Environment(GameModel.self) private var model
    @State private var image: Image?
    @State private var video: URL?
    @State private var failed = false

    var body: some View {
        VStack(spacing: 20) {
            if ShareLook.moving {
                movingCard
            } else if let image {
                image
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    .accessibilityLabel("Share card of \(model.state.titleName), \(model.state.points.total) points, level \(model.state.level)")
                ShareLink(item: image, preview: SharePreview(model.state.titleName, image: image)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Ink.body, in: Capsule())
                        .foregroundStyle(Ink.eye)
                }
            } else if failed {
                VStack(spacing: 14) {
                    Text("Couldn’t draw the card.")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                    Button("Try again") { failed = false; render() }
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                }
                .foregroundStyle(Ink.body)
            } else {
                ProgressView()
            }
        }
        .padding(24)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Ink.eye)
        .task { ShareLook.moving ? await makeVideo() : render() }
    }

    private var line: String {
        model.state.recentLines.last ?? "my alibi is adorable."
    }

    /// C and D: the card plays live here while the video is made, then shares as an MP4.
    @ViewBuilder private var movingCard: some View {
        let pose = cardPose
        TimelineView(.animation(minimumInterval: 1 / 30)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 4)
            Group {
                if ShareLook.level == 3 {
                    StoryCardView(state: model.state, pose: pose, line: line, time: t)
                        .scaleEffect(0.78).frame(width: 360 * 0.78, height: 640 * 0.78)
                } else {
                    ShareCardView(state: model.state, pose: pose, line: line, time: t)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Label("Video", systemImage: "play.fill")
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.black.opacity(0.5), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(12)
            }
        }
        .accessibilityLabel("Moving share card of \(model.state.titleName)")
        if let video {
            ShareLink(item: video) {
                Label("Share video", systemImage: "square.and.arrow.up")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Ink.body, in: Capsule())
                    .foregroundStyle(Ink.eye)
            }
        } else if failed {
            Button("Try again") { failed = false; Task { await makeVideo() } }
                .font(.system(.headline, design: .rounded).weight(.heavy))
        } else {
            HStack(spacing: 10) {
                ProgressView()
                Text("Making the video…").font(.system(.headline, design: .rounded).weight(.heavy))
            }
            .foregroundStyle(Ink.body)
            .frame(minHeight: 52)
        }
    }

    private var cardPose: GremlinPose {
        var pose = model.pose
        pose.look = .zero
        return pose
    }

    private func makeVideo() async {
        let pose = cardPose
        let state = model.state, line = line
        do {
            if ShareLook.level == 3 {
                video = try await CardVideo.make(size: CGSize(width: 360, height: 640)) { t in
                    StoryCardView(state: state, pose: pose, line: line, time: t)
                }
            } else {
                video = try await CardVideo.make(size: CGSize(width: 360, height: 450)) { t in
                    ShareCardView(state: state, pose: pose, line: line, time: t)
                }
            }
        } catch {
            failed = true
        }
    }

    private func render() {
        var pose = model.pose
        if pose.sleeping == false { pose.look = .zero }
        let renderer = ImageRenderer(content: ShareCardView(state: model.state, pose: pose, line: ShareLook.level == 1 ? line : nil))
        renderer.scale = 3 // 1080 × 1350
        if let ui = renderer.uiImage { image = Image(uiImage: ui) } else { failed = true }
    }
}
