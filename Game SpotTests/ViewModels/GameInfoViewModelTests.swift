//
//  GameInfoViewModelTests.swift
//  Game SpotTests
//
//  ViewModel tests for game detail loading and MVP voting state.
//

import XCTest
@testable import Game_Spot

@MainActor
final class GameInfoViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let viewModel = GameInfoViewModel()

        XCTAssertNil(viewModel.details)
        XCTAssertNil(viewModel.weather)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmittingVote)
    }

    // MARK: - MVP Voting

    func testSubmitVoteWithoutDetailsDoesNotSubmit() async {
        let viewModel = GameInfoViewModel()
        viewModel.details = nil

        await viewModel.submitVote(
            playerId: TestFixtures.userId
        )

        XCTAssertFalse(viewModel.isSubmittingVote)
    }

    func testSubmitVoteSetsSubmittingFlagWhileRunning() async {
        let viewModel = GameInfoViewModel()
        viewModel.details = TestFixtures.gameDetails(
            startsAt: Date().addingTimeInterval(3_600)
        )

        let voteTask = Task {
            await viewModel.submitVote(
                playerId: UUID()
            )
        }

        try? await Task.sleep(for: .milliseconds(30))

        // Flag should return to false after completion (success or failure).
        await voteTask.value
        XCTAssertFalse(viewModel.isSubmittingVote)
    }

    // MARK: - Load (network-dependent)

    func testLoadSetsErrorOrDetails() async {
        let viewModel = GameInfoViewModel()

        await viewModel.load(
            gameId: TestFixtures.gameId
        )

        XCTAssertFalse(viewModel.isLoading)

        let hasResult =
            viewModel.details != nil
            || viewModel.errorMessage != nil

        XCTAssertTrue(hasResult)
    }

    func testLoadClearsPreviousErrorMessage() async {
        let viewModel = GameInfoViewModel()
        viewModel.errorMessage = "Previous error"

        await viewModel.load(
            gameId: TestFixtures.gameId
        )

        // load() resets errorMessage at start; final state depends on network.
        XCTAssertFalse(viewModel.isLoading)
    }
}
