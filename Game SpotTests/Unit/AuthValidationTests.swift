//
//  AuthValidationTests.swift
//  Game SpotTests
//
//  Validates AuthViewModel.isValid and AuthView sign-up password rules.
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

    // MARK: - Sign Up Rules (AuthView)

    func testPasswordChecksRequireEightCharacters() {
        let checks = AuthValidationLogic.passwordChecks(
            for: "Short1"
        )

        XCTAssertFalse(checks[0].passed)
    }

    func testPasswordChecksRequireUppercaseAndNumber() {
        let checks = AuthValidationLogic.passwordChecks(
            for: "password1"
        )

        XCTAssertFalse(checks[1].passed)

        let validChecks = AuthValidationLogic.passwordChecks(
            for: "Password1"
        )

        XCTAssertTrue(validChecks.allSatisfy(\.passed))
    }

    @MainActor
    func testCanSubmitSignUpRequiresMatchingPasswords() {
        let viewModel = AuthViewModel()
        viewModel.email = "user@example.com"
        viewModel.password = "Password1"

        XCTAssertFalse(
            AuthValidationLogic.canSubmitSignUp(
                email: viewModel.email,
                password: viewModel.password,
                confirmPassword: "Password2",
                viewModelIsValid: viewModel.isValid
            )
        )

        XCTAssertTrue(
            AuthValidationLogic.canSubmitSignUp(
                email: viewModel.email,
                password: viewModel.password,
                confirmPassword: "Password1",
                viewModelIsValid: viewModel.isValid
            )
        )
    }
}
