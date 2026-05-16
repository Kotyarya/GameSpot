import SwiftUI

@main
struct Game_SpotApp: App {
    
    @StateObject private var session = SessionManager()
    @StateObject private var router = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .fontDesign(.rounded)
                .environmentObject(session)
                .environmentObject(router)
        }
    }
}
