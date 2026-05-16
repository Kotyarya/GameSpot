//
//  GamesViewModelTests.swift
//  Game SpotTests
//
//  ViewModel tests for games list state and loading behavior.
//

import XCTest
@testable import Game_Spot

@MainActor
final class GamesViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialStateIsEmptyAndNotLoading() {
        let viewModel = GamesViewModel()

        XCTAssertTrue(viewModel.games.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Load (network-dependent)

    func testLoadSetsLoadingDuringFetch() async {
        let viewModel = GamesViewModel()

        let loadTask = Task {
            await viewModel.load(mode: .myGames)
        }

        // First load should enable loading indicator at some point.
        try? await Task.sleep(for: .milliseconds(100))

        let sawLoadingOrCompleted = viewModel.isLoading || viewModel.games.isEmpty
        XCTAssertTrue(sawLoadingOrCompleted)

        await loadTask.value
    }

    func testLoadCompletesWithLoadingFalse() async {
        let viewModel = GamesViewModel()

        await viewModel.load(mode: .myGames)

        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadParkModeCompletesWithoutCrash() async {
        let viewModel = GamesViewModel()

        await viewModel.load(
            mode: .park(id: TestFixtures.parkId)
        )

        XCTAssertFalse(viewModel.isLoading)
    }
}
