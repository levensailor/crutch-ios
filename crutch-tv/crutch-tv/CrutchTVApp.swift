import SwiftUI

@main
struct CrutchTVApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SongsListView()
            }
        }
    }
}
