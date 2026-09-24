import AVFoundation
import UIKit

enum Sound: String, CaseIterable {
    case pop, chomp, boing, whoosh, win, lose, snore, stamp
}

/// Short bundled effects. Ambient session: respects the silent switch and mixes with music.
@MainActor
final class SoundPlayer {
    var enabled = true
    private var players: [Sound: AVAudioPlayer] = [:]

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        for sound in Sound.allCases {
            guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[sound] = player
        }
    }

    func play(_ sound: Sound) {
        guard enabled, let player = players[sound] else { return }
        player.currentTime = 0
        player.play()
    }
}

@MainActor
final class Haptics {
    var enabled = true
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let notify = UINotificationFeedbackGenerator()

    enum Kind { case tap, squish, thud, success, nope }

    func play(_ kind: Kind, intensity: CGFloat = 1) {
        guard enabled else { return }
        switch kind {
        case .tap: light.impactOccurred(intensity: intensity)
        case .squish: soft.impactOccurred(intensity: intensity)
        case .thud: rigid.impactOccurred(intensity: intensity)
        case .success: notify.notificationOccurred(.success)
        case .nope: notify.notificationOccurred(.warning)
        }
    }
}
