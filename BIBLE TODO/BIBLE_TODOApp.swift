import SwiftUI

@main
struct BIBLE_TODOApp: App {
    @StateObject private var appState = AppState(
        supabaseClient: SupabaseConfig.makeClient(),
        persistence: UserDefaultsPersistence()
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
