#if DEBUG

import SwiftUI

enum TeamActionUITestScenario: String {

    case join
    case leave
    case error

    static var current: TeamActionUITestScenario? {
        let prefix = "--ui-test-team-sheet="

        guard
            let argument = ProcessInfo.processInfo.arguments.first(
                where: { $0.hasPrefix(prefix) }
            )
        else {
            return nil
        }

        return TeamActionUITestScenario(
            rawValue: String(argument.dropFirst(prefix.count))
        )
    }
}

struct TeamActionUITestHarness: View {

    let scenario: TeamActionUITestScenario

    @State private var isPresented = false
    @State private var joinCallCount = 0
    @State private var leaveCallCount = 0

    private let currentUserId = UUID(
        uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
    )!

    var body: some View {

        VStack(spacing: 16) {

            Text("Join calls: \(joinCallCount)")
                .accessibilityIdentifier("team.harness.joinCalls")

            Text("Leave calls: \(leaveCallCount)")
                .accessibilityIdentifier("team.harness.leaveCalls")
        }
        .onAppear {
            isPresented = true
        }
        .fullScreenCover(isPresented: $isPresented) {

            JoinGameSheetView(
                details: details,
                currentUserId: currentUserId,
                onJoin: { _ in
                    joinCallCount += 1
                    try await completeAction()
                },
                onLeave: {
                    leaveCallCount += 1
                    try await completeAction()
                }
            )
        }
    }

    private var details: GameDetails {
        let otherPlayer = Player(
            id: UUID(
                uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"
            )!,
            username: "player2",
            avatarUrl: nil,
            team: .beta,
            rating: 400,
            gamesPlayed: 5,
            createdAt: Date(),
            isTopRated: false,
            isMostActive: false,
            isNewest: false,
            mvpVotesCount: 0,
            isVotedByCurrentUser: false
        )
        let currentPlayer = Player(
            id: currentUserId,
            username: "testuser",
            avatarUrl: nil,
            team: .alpha,
            rating: 500,
            gamesPlayed: 10,
            createdAt: Date(),
            isTopRated: false,
            isMostActive: false,
            isNewest: false,
            mvpVotesCount: 0,
            isVotedByCurrentUser: false
        )
        let players = scenario == .leave
            ? [currentPlayer, otherPlayer]
            : [otherPlayer]

        return GameDetails(
            id: UUID(
                uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"
            )!,
            startsAt: Date().addingTimeInterval(3_600),
            durationMinutes: 60,
            maxPlayers: 10,
            joinedPlayers: players.count,
            isFinished: false,
            sport: Sport(
                id: UUID(
                    uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"
                )!,
                name: "football"
            ),
            park: ParkShort(
                id: UUID(
                    uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE"
                )!,
                name: "Test Park",
                latitude: 50.45,
                longitude: 30.52,
                hasLighting: true,
                overallAvg: 4.5
            ),
            players: players,
            isJoined: scenario == .leave,
            mvpPlayer: nil,
            isInProgress: false,
            isProcessed: false,
            mvpVotingOpen: false,
            hasVoted: false
        )
    }

    @MainActor
    private func completeAction() async throws {

        let delay: Duration = scenario == .error
            ? .seconds(2)
            : .milliseconds(800)

        try await Task.sleep(for: delay)

        if scenario == .error {
            throw TeamActionUITestError.requestFailed
        }
    }
}

private enum TeamActionUITestError: LocalizedError {

    case requestFailed

    var errorDescription: String? {
        "Unable to update team."
    }
}

#endif
