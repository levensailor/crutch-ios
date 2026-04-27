import SwiftUI

@main
struct CrutchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SongsListView()
            }
        }
    }
}

