//
//  AuthValidationTests.swift
//  Game SpotTests
//
//  Validates AuthViewModel.isValid and shared password rules.
//

import XCTest
@testable import Game_Spot

final class AuthValidationTests: XCTestCase {

    // MARK: - AuthViewModel

    @MainActor
    func testAuthViewModelIsValidRequiresEmailPasswordAndMinimumLength() {
        let viewModel = AuthViewModel()

        viewModel.email = ""
        viewModel.password = "secret"
        XCTAssertFalse(viewModel.isValid)

        viewModel.email = "user@example.com"
        viewModel.password = "12345"
        XCTAssertFalse(viewModel.isValid)

        viewModel.password = "123456"
        XCTAssertTrue(viewModel.isValid)
    }

    @MainActor
    func testAuthViewModelInitialState() {
        let viewModel = AuthViewModel()

        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Shared Password Rules

    func testPasswordChecksRequireEightCharacters() {
        let checks = PasswordPolicy.checks(
            for: "Short1"
        )

        XCTAssertFalse(checks[0].passed)
    }

    func testPasswordChecksRequireUppercaseAndNumber() {
        let checks = PasswordPolicy.checks(
            for: "password1"
        )

        XCTAssertFalse(checks[1].passed)

        let validChecks = PasswordPolicy.checks(
            for: "Password1"
        )

        XCTAssertTrue(validChecks.allSatisfy(\.passed))
    }

    func testSharedPolicyRequiresMatchingPasswords() {
        XCTAssertFalse(
            PasswordPolicy.passwordsMatch(
                "Password1",
                confirmation: "Password2"
            )
        )

        XCTAssertTrue(
            PasswordPolicy.passwordsMatch(
                "Password1",
                confirmation: "Password1"
            )
        )
    }
}
