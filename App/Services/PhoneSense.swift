import CoreMotion
import UIKit

/// Things the phone itself does that the gremlin can notice. No permissions needed for any of them.
enum PhoneEvent: String {
    case lowBattery, charging, shake, screenshot, recording
}

/// Review S31 (DEBUG only): how much of the phone it notices. A nothing; B battery, charging and a shake;
/// C also screenshots and screen recording; D also which way the phone tilts (its eyes and lean follow).
enum PhoneAware {
    static var level: Int {
        Variant.on("S31D") ? 3 : Variant.on("S31C") ? 2 : Variant.on("S31B") ? 1 : 0
    }

    static func allows(_ event: PhoneEvent) -> Bool {
        switch event {
        case .lowBattery, .charging, .shake: level >= 1
        case .screenshot, .recording: level >= 2
        }
    }
}

extension Notification.Name {
    static let lmDeviceShook = Notification.Name("lm.deviceShook")
}

extension UIWindow {
    /// SwiftUI has no shake gesture: the window passes it on.
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake { NotificationCenter.default.post(name: .lmDeviceShook, object: nil) }
        super.motionEnded(motion, with: event)
    }
}

@MainActor
final class PhoneSense {
    private var observers: [NSObjectProtocol] = []
    private let motion = CMMotionManager()
    private var lastState: UIDevice.BatteryState = .unknown
    private var wasLow = false

    /// Battery left in whole percent, or -1 when unknown (the simulator).
    static var batteryPercent: Int {
        let level = UIDevice.current.batteryLevel
        return level < 0 ? -1 : Int((level * 100).rounded())
    }

    func start(onEvent: @escaping (PhoneEvent, Int) -> Void, onTilt: @escaping (CGSize) -> Void) {
        stop()
        let level = PhoneAware.level
        guard level > 0 else { return }
        let nc = NotificationCenter.default
        UIDevice.current.isBatteryMonitoringEnabled = true
        lastState = UIDevice.current.batteryState
        wasLow = isLow
        for name in [UIDevice.batteryLevelDidChangeNotification, UIDevice.batteryStateDidChangeNotification] {
            observers.append(nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.batteryChanged(onEvent) }
            })
        }
        observers.append(nc.addObserver(forName: .lmDeviceShook, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { onEvent(.shake, Self.batteryPercent) }
        })
        if level >= 2 {
            observers.append(nc.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { onEvent(.screenshot, Self.batteryPercent) }
            })
            observers.append(nc.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main) { n in
                MainActor.assumeIsolated {
                    if (n.object as? UIScreen)?.isCaptured == true { onEvent(.recording, Self.batteryPercent) }
                }
            })
        }
        if level >= 3 && motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 1.0 / 15
            motion.startDeviceMotionUpdates(to: .main) { data, _ in
                guard let g = data?.gravity else { return }
                MainActor.assumeIsolated { onTilt(CGSize(width: g.x, height: g.y)) }
            }
        }
    }

    func stop() {
        for o in observers { NotificationCenter.default.removeObserver(o) }
        observers = []
        if motion.isDeviceMotionActive { motion.stopDeviceMotionUpdates() }
    }

    private var isLow: Bool {
        let pct = Self.batteryPercent
        return UIDevice.current.batteryState == .unplugged && pct >= 0 && pct <= 20
    }

    private func batteryChanged(_ onEvent: (PhoneEvent, Int) -> Void) {
        let state = UIDevice.current.batteryState
        if (state == .charging || state == .full) && lastState == .unplugged { onEvent(.charging, Self.batteryPercent) }
        let low = isLow
        if low && !wasLow { onEvent(.lowBattery, Self.batteryPercent) }
        wasLow = low
        lastState = state
    }
}
