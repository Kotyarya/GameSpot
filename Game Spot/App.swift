import SwiftUI

@main
struct Game_SpotApp: App {

    var body: some Scene {
        WindowGroup {
            appContent
                .fontDesign(.rounded)
        }
    }

    @ViewBuilder
    private var appContent: some View {

        #if DEBUG
        if let scenario = TeamActionUITestScenario.current {

            TeamActionUITestHarness(scenario: scenario)

        } else {

            rootView
        }
        #else
        rootView
        #endif
    }

    private var rootView: some View {

        RootAppContent()
    }
}

private struct RootAppContent: View {

    @StateObject private var session = SessionManager()
    @StateObject private var router = AppRouter()

    var body: some View {

        RootView()
            .environmentObject(session)
            .environmentObject(router)
    }
}
