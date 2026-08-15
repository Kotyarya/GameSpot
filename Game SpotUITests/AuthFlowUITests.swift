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
        signOutIfNeeded()
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

    func testAuthScreenDoesNotOfferUnavailableAppleSignIn() throws {
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 15))

        XCTAssertFalse(
            app.buttons["Sign in with Apple"].exists,
            "Version 1.0 must not offer an unavailable sign-in method."
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

    // MARK: - Authenticated Journey

    func testAuthenticatedUserCanOpenPrivacyPolicy() throws {
        let environment = ProcessInfo.processInfo.environment

        guard
            let email = environment["GAMESPOT_UI_TEST_EMAIL"],
            !email.isEmpty,
            let password = environment["GAMESPOT_UI_TEST_PASSWORD"],
            !password.isEmpty
        else {
            throw XCTSkip(
                "Set GAMESPOT_UI_TEST_EMAIL and GAMESPOT_UI_TEST_PASSWORD "
                + "for a fully onboarded test account."
            )
        }

        addTeardownBlock { [weak self] in
            self?.signOutIfNeeded()
        }

        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]

        XCTAssertTrue(emailField.waitForExistence(timeout: 15))
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))

        emailField.tap()
        emailField.typeText(email)

        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["Sign In"].tap()

        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(
            profileTab.waitForExistence(timeout: 20),
            "A valid, fully onboarded test account should reach the main tabs."
        )

        profileTab.tap()

        let privacyLink = app.descendants(matching: .any)[
            "profile.privacyPolicy"
        ]
        XCTAssertTrue(privacyLink.waitForExistence(timeout: 10))
        privacyLink.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["privacyPolicy.screen"]
                .waitForExistence(timeout: 5)
        )
    }

    // MARK: - Session Isolation

    private func signOutIfNeeded() {
        let signInButton = app.buttons["Sign In"]

        if signInButton.waitForExistence(timeout: 15) {
            return
        }

        let profileTab = app.tabBars.buttons["Profile"]

        guard profileTab.waitForExistence(timeout: 10) else {
            return
        }

        profileTab.tap()

        let signOutButton = app.buttons["Sign Out"]

        guard signOutButton.waitForExistence(timeout: 10) else {
            return
        }

        signOutButton.tap()
        _ = signInButton.waitForExistence(timeout: 15)
    }
}
