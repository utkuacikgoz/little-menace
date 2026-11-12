import UIKit

/// Things the phone itself does that the gremlin can notice. No permissions needed for any of them.
enum PhoneEvent: String {
    case lowBattery, charging, shake
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
    private var lastState: UIDevice.BatteryState = .unknown
    private var wasLow = false

    /// Battery left in whole percent, or -1 when unknown (the simulator).
    static var batteryPercent: Int {
        let level = UIDevice.current.batteryLevel
        return level < 0 ? -1 : Int((level * 100).rounded())
    }

    func start(onEvent: @escaping (PhoneEvent, Int) -> Void) {
        stop()
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
    }

    func stop() {
        for o in observers { NotificationCenter.default.removeObserver(o) }
        observers = []
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
