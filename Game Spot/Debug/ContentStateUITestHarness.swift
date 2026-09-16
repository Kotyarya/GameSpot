#if DEBUG

import SwiftUI

enum ContentStateUITestScenario: String {

    case error
    case slow
    case nativeLoading
    case gameCards

    static var current: ContentStateUITestScenario? {
        let prefix = "--ui-test-content-state="

        guard
            let argument = ProcessInfo.processInfo.arguments.first(
                where: { $0.hasPrefix(prefix) }
            )
        else {
            return nil
        }

        return ContentStateUITestScenario(
            rawValue: String(argument.dropFirst(prefix.count))
        )
    }
}

struct ContentStateUITestHarness: View {

    let scenario: ContentStateUITestScenario

    @State private var isLoading: Bool

    @State private var showsError: Bool

    @State private var retryCount = 0

    @StateObject private var router = AppRouter()

    init(
        scenario: ContentStateUITestScenario
    ) {

        self.scenario = scenario
        _isLoading = State(initialValue: scenario == .slow)
        _showsError = State(initialValue: scenario == .error)
    }

    var body: some View {

        Group {

            if scenario == .nativeLoading {

                NativeLoadingView(
                    title: "Loading Profile"
                )

            } else if scenario == .gameCards {

                gameCards

            } else {

                contentStates
            }
        }
        .task {
            guard scenario == .slow else {
                return
            }

            try? await Task.sleep(
                for: .seconds(6)
            )

            isLoading = false
        }
    }

    private var contentStates: some View {

        ZStack {

            if isLoading {

                LoadingView()
                    .accessibilityIdentifier(
                        "contentState.harness.loading"
                    )

            } else if showsError {

                ContentStateView(
                    title: "Couldn’t Load Games",
                    message: "Check your connection and try again.",
                    systemImage: "wifi.exclamationmark",
                    accessibilityIdentifier: "contentState.harness.error",
                    actionTitle: "Try Again",
                    action: retry
                )

            } else {

                ContentStateView(
                    title: "No Games Yet",
                    message: "Explore a park and join your first game.",
                    systemImage: "sportscourt",
                    accessibilityIdentifier: "contentState.harness.empty"
                )
            }
        }
        .overlay(alignment: .top) {
            Text("Retry calls: \(retryCount)")
                .accessibilityIdentifier(
                    "contentState.harness.retryCount"
                )
        }
    }

    private var gameCards: some View {

        NavigationStack {

            VStack(spacing: 24) {

                GameCard(
                    game: game(
                        id: UUID(
                            uuidString:
                                "00000000-0000-0000-0000-000000000001"
                        )!,
                        startsAt: Date().addingTimeInterval(86_400),
                        isFinished: false
                    )
                )

                GameCard(
                    game: game(
                        id: UUID(
                            uuidString:
                                "00000000-0000-0000-0000-000000000002"
                        )!,
                        startsAt: Date().addingTimeInterval(-86_400),
                        isFinished: true
                    )
                )
            }
            .padding()
        }
        .environmentObject(router)
    }

    private func game(
        id: UUID,
        startsAt: Date,
        isFinished: Bool
    ) -> Game {

        Game(
            id: id,
            parkId: UUID(),
            creatorId: UUID(),
            sport: Sport(
                id: UUID(),
                name: "basketball"
            ),
            startsAt: startsAt,
            durationMinutes: 60,
            maxPlayers: 10,
            isFinished: isFinished,
            isProcessed: isFinished,
            isInProgress: false,
            mvpVotingOpen: false,
            joinedPlayers: 6
        )
    }

    private func retry() {
        retryCount += 1
        showsError = false
        isLoading = true

        Task {
            try? await Task.sleep(
                for: .milliseconds(500)
            )

            isLoading = false
        }
    }
}

#endif
