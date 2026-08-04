import ActivityKit
import Foundation

struct SongPerformanceAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var songIndex: Int
        var songCount: Int
    }
}
