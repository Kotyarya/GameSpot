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
        if ProcessInfo.processInfo.arguments.contains(
            "--ui-test-location-permission"
        ) {

            OnBoardingView()

        } else if let scenario = ContentStateUITestScenario.current {

            ContentStateUITestHarness(scenario: scenario)

        } else if let scenario = TeamActionUITestScenario.current {

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
    @StateObject private var authLinks = AuthLinkCoordinator()

    var body: some View {

        RootView()
            .environmentObject(session)
            .environmentObject(router)
            .environmentObject(authLinks)
            .onOpenURL { url in
                Task {
                    let route = await authLinks.handle(url)

                    if route == .emailConfirmation,
                       authLinks.state == .emailConfirmed {
                        session.refreshUser()
                        authLinks.reset()
                    }
                }
            }
    }
}
