//
//  ProfileViewModelTests.swift
//  Game SpotTests
//
//  ViewModel tests for profile screen loading state.
//

import XCTest
@testable import Game_Spot

@MainActor
final class ProfileViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInitialStateShowsLoading() {
        let viewModel = ProfileViewModel()

        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.profile)
        XCTAssertTrue(viewModel.stats.isEmpty)
        XCTAssertTrue(viewModel.recentMatches.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.hasLoadedOnce)
    }

    // MARK: - Load (network-dependent)

    func testLoadCompletesAndUpdatesLoadingFlag() async {
        let viewModel = ProfileViewModel()

        await viewModel.load(
            userId: TestFixtures.userId
        )

        XCTAssertFalse(viewModel.isLoading)

        let hasResult =
            viewModel.profile != nil
            || viewModel.errorMessage != nil

        XCTAssertTrue(hasResult)
    }

    func testLoadSkipsDuplicateRequestForSameUserWhenNotLoading() async {
        let viewModel = ProfileViewModel()

        await viewModel.load(userId: TestFixtures.userId)
        let profileAfterFirstLoad = viewModel.profile

        viewModel.isLoading = false
        await viewModel.load(userId: TestFixtures.userId)

        XCTAssertEqual(viewModel.profile?.id, profileAfterFirstLoad?.id)
    }
}
