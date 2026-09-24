import UserNotifications
import MenaceCore

/// Applies `ReminderPolicy.plan` to the system queue. Only touches its own identifiers.
@MainActor
final class ReminderScheduler {
    private let center = UNUserNotificationCenter.current()
    private let prefix = "lm."

    /// Returns whether the user allowed notifications.
    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func isAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    func apply(_ plan: [PlannedReminder]) async {
        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(prefix) })
        guard !plan.isEmpty, await isAuthorized() else { return }
        for reminder in plan {
            let content = UNMutableNotificationContent()
            content.title = "Crumb"
            content.body = reminder.body
            content.sound = .default
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: prefix + reminder.id, content: content, trigger: trigger))
        }
    }
}
