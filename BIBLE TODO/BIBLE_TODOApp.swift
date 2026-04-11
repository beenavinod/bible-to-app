import SwiftUI

@main
struct BIBLE_TODOApp: App {
    @StateObject private var appState = AppState(
        service: MockBibleService(),
        persistence: UserDefaultsPersistence()
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
