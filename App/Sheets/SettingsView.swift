import SwiftUI
import UIKit
import MenaceCore

/// Replace before App Store submission. Kept in one place so they are easy to find.
enum AppLinks {
    static let privacy = URL(string: "https://example.com/little-menace/privacy")!
    static let support = URL(string: "https://example.com/little-menace/support")!
}

struct SettingsView: View {
    @Environment(GameModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        let prefs = model.state.prefs
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: Binding(get: { prefs.sound }, set: { model.setSound($0) })) {
                        Label("Sound", systemImage: "speaker.wave.2.fill")
                    }
                    Toggle(isOn: Binding(get: { prefs.haptics }, set: { model.setHaptics($0) })) {
                        Label("Haptics", systemImage: "hand.tap.fill")
                    }
                }

                Section {
                    Toggle(isOn: Binding(get: { prefs.remindersEnabled }, set: { on in Task { await model.setReminders(on) } })) {
                        Label("Reminders", systemImage: "bell.fill")
                    }
                    if prefs.remindersEnabled {
                        DatePicker("Time", selection: Binding(get: { reminderTime(prefs) }, set: { model.setReminderTime($0) }),
                                   displayedComponents: .hourAndMinute)
                    }
                    if model.notificationsDenied {
                        Button("Notifications are off in iOS Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                        .font(.footnote)
                    }
                } footer: {
                    Text("At most one gentle nudge a day, and they stop if you're away for a few days.")
                }

                Section {
                    Button {
                        Task { await model.purchases.restore() }
                    } label: {
                        HStack {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                            Spacer()
                            if model.purchases.state == .purchasing { ProgressView() }
                            if model.purchases.state == .restored { Image(systemName: "checkmark") }
                        }
                    }
                    Link(destination: AppLinks.privacy) { Label("Privacy", systemImage: "hand.raised.fill") }
                    Link(destination: AppLinks.support) { Label("Support", systemImage: "questionmark.circle.fill") }
                }

                Section {
                    Button(role: .destructive) { confirmReset = true } label: {
                        Label("Start Over", systemImage: "arrow.counterclockwise")
                    }
                } footer: {
                    Text("Start Over resets \(model.state.name)'s level, stamps and discoveries. Purchases stay yours.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .confirmationDialog("Start over with a new Crumb?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Start Over", role: .destructive) {
                    model.reset()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    private func reminderTime(_ prefs: Preferences) -> Date {
        Calendar.current.date(bySettingHour: prefs.reminderHour, minute: prefs.reminderMinute, second: 0, of: Date()) ?? Date()
    }
}
