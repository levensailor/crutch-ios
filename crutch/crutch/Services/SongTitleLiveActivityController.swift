import ActivityKit
import Foundation

@MainActor
final class SongTitleLiveActivityController {
    static let shared = SongTitleLiveActivityController()

    private var activity: Activity<SongPerformanceAttributes>?

    func show(title: String, songIndex: Int, songCount: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let state = SongPerformanceAttributes.ContentState(
            title: title,
            songIndex: songIndex,
            songCount: songCount
        )

        if let activity {
            Task {
                await activity.update(ActivityContent(state: state, staleDate: nil))
            }
            return
        }

        do {
            activity = try Activity.request(
                attributes: SongPerformanceAttributes(),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            // Live Activities may be disabled by Focus / Low Power / system policy.
            print("Unable to start song title Live Activity: \(error)")
        }
    }

    func end() {
        guard let activity else {
            return
        }

        let ending = activity
        self.activity = nil

        Task {
            await ending.end(nil, dismissalPolicy: .immediate)
        }
    }
}
