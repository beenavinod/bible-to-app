import SwiftUI

@main
struct BIBLE_TODOApp: App {
    @StateObject private var appState = AppState(
        supabaseClient: SupabaseConfig.makeClient(),
        persistence: UserDefaultsPersistence()
    )
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(subscriptionManager)
        }
    }
}
