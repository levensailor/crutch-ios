import ActivityKit
import Foundation
import OSLog

@MainActor
final class SongTitleLiveActivityController {
    static let shared = SongTitleLiveActivityController()

    private let logger = Logger(subsystem: "levensailor.crutch", category: "LiveActivity")
    private var activity: Activity<SongPerformanceAttributes>?

    func show(title: String, songIndex: Int, songCount: Int) {
        let auth = ActivityAuthorizationInfo()
        guard auth.areActivitiesEnabled else {
            logger.error("Live Activities are disabled system-wide or for this app.")
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

        // End any orphaned activities from a previous launch before requesting a new one.
        for existing in Activity<SongPerformanceAttributes>.activities {
            Task {
                await existing.end(nil, dismissalPolicy: .immediate)
            }
        }

        do {
            activity = try Activity.request(
                attributes: SongPerformanceAttributes(),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            logger.info("Started Live Activity for \(title, privacy: .public)")
        } catch {
            logger.error("Unable to start song title Live Activity: \(error.localizedDescription, privacy: .public)")
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
