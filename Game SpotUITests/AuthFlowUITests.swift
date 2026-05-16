//
//  AuthFlowUITests.swift
//  Game SpotUITests
//
//  Basic UI tests for the authentication screen.
//

import XCTest

final class AuthFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    // MARK: - Launch

    func testAppLaunches() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    // MARK: - Auth Screen

    func testAuthScreenDisplaysSignInElements() throws {
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(
            signInButton.waitForExistence(timeout: 15),
            "Sign In button should appear on the auth screen or after loading."
        )
    }

    func testAuthScreenCanSwitchToSignUpMode() throws {
        let signUpLink = app.staticTexts["Sign Up"]
        XCTAssertTrue(
            signUpLink.waitForExistence(timeout: 15)
        )

        signUpLink.tap()

        let createAccountButton = app.buttons["Create Account"]
        XCTAssertTrue(
            createAccountButton.waitForExistence(timeout: 5)
        )
    }

    func testAuthScreenEmailFieldAcceptsInput() throws {
        let emailField = app.textFields["Enter your email"]
        XCTAssertTrue(
            emailField.waitForExistence(timeout: 15)
        )

        emailField.tap()
        emailField.typeText("test@example.com")

        XCTAssertEqual(
            emailField.value as? String,
            "test@example.com"
        )
    }
}
