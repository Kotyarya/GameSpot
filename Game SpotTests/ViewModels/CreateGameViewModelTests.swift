//
//  CreateGameViewModelTests.swift
//  Game SpotTests
//
//  ViewModel tests for create-game validation and error handling.
//

import XCTest
@testable import Game_Spot

@MainActor
final class CreateGameViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let viewModel = CreateGameViewModel()

        XCTAssertNil(viewModel.selectedSport)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Validation

    func testCreateGameWithoutSportReturnsNilAndSetsError() async {
        let viewModel = CreateGameViewModel()
        viewModel.selectedSport = nil

        let result = await viewModel.createGame(
            parkId: TestFixtures.parkId
        )

        XCTAssertNil(result)
        XCTAssertEqual(viewModel.errorMessage, "Select sport")
        XCTAssertFalse(viewModel.isLoading)
    }

    func testCreateGameWithSportAttemptsNetworkCall() async {
        let viewModel = CreateGameViewModel()
        viewModel.selectedSport = TestFixtures.sport()
        viewModel.startsAt = Date().addingTimeInterval(3_600)

        let result = await viewModel.createGame(
            parkId: TestFixtures.parkId
        )

        XCTAssertFalse(viewModel.isLoading)

        // Result may be nil on network/auth failure; test ensures no crash.
        if result == nil {
            XCTAssertNotNil(viewModel.errorMessage)
        }
    }
}
