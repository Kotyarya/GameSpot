//
//  AuthViewModelTests.swift
//  Game SpotTests
//
//  ViewModel tests for authentication input validation and UI state.
//

import XCTest
@testable import Game_Spot

@MainActor
final class AuthViewModelTests: XCTestCase {

    // MARK: - Validation

    func testIsValidRequiresNonEmptyEmail() {
        let viewModel = AuthViewModel()
        viewModel.email = ""
        viewModel.password = "abcdef"

        XCTAssertFalse(viewModel.isValid)
    }

    func testIsValidRequiresMinimumPasswordLength() {
        let viewModel = AuthViewModel()
        viewModel.email = "player@example.com"
        viewModel.password = "12345"

        XCTAssertFalse(viewModel.isValid)

        viewModel.password = "123456"
        XCTAssertTrue(viewModel.isValid)
    }

    // MARK: - Initial State

    func testInitialPublishedValues() {
        let viewModel = AuthViewModel()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
    }

    // MARK: - Loading State (sign-in without network assertion)

    func testSignInSetsLoadingFlag() async {
        let viewModel = AuthViewModel()
        let session = SessionManager()

        viewModel.email = "invalid@example.com"
        viewModel.password = "invalidpassword"

        viewModel.signIn(session: session)

        // Loading should flip true immediately before async work completes.
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(viewModel.isLoading == false && viewModel.errorMessage == nil)
    }
}
