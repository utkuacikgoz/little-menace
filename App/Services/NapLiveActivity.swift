import ActivityKit
import Foundation
import MenaceCore

/// Starts the nap's Live Activity when a nap starts and ends it when the gremlin wakes, however that happens.
@MainActor
final class NapLiveActivity {
    func napStarted(_ s: PetState) {
        end()
        guard ActivityAuthorizationInfo().areActivitiesEnabled, let wake = TimeModel.expectedWake(s) else { return }
        let attributes = NapAttributes(name: s.titleName, hat: s.wardrobe.hat, neck: s.wardrobe.neck,
                                       fur: s.wardrobe.fur, theme: s.wardrobe.theme)
        _ = try? Activity.request(attributes: attributes,
                                  content: ActivityContent(state: .init(startedAt: s.napStartedAt ?? Date(), wakesAt: wake), staleDate: wake.addingTimeInterval(60)),
                                  pushType: nil)
    }

    func end() {
        for activity in Activity<NapAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
