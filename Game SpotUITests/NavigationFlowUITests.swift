//
//  NavigationFlowUITests.swift
//  Game SpotUITests
//
//  Basic tab navigation smoke tests (requires an authenticated session).
//

import XCTest

final class NavigationFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    // MARK: - Tab Bar

    func testMainTabBarVisibleWhenAuthenticated() throws {
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

        app.launch()
        signOutIfNeeded()

        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]

        XCTAssertTrue(emailField.waitForExistence(timeout: 15))
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))

        emailField.tap()
        emailField.typeText(email)

        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["Sign In"].tap()

        let mapTab = tabButton(
            title: "Map",
            identifier: "map.fill"
        )
        let gamesTab = tabButton(
            title: "My Games",
            identifier: "sportscourt.fill"
        )
        let profileTab = tabButton(
            title: "Profile",
            identifier: "person.crop.circle"
        )

        XCTAssertTrue(
            mapTab.waitForExistence(timeout: 20),
            "Authenticated navigation must show the Map tab."
        )
        dismissPasswordSavePromptIfPresent(timeout: 5)
        XCTAssertTrue(gamesTab.waitForExistence(timeout: 5))
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))

        mapTab.tap()
        XCTAssertTrue(mapTab.isSelected)

        gamesTab.tap()
        XCTAssertTrue(
            app.navigationBars["My Games"].waitForExistence(timeout: 10)
        )
        XCTAssertTrue(gamesTab.isSelected)

        profileTab.tap()
        XCTAssertTrue(
            app.staticTexts["Overall Profile"].waitForExistence(timeout: 10),
            "Selecting Profile must load authenticated profile content."
        )
        XCTAssertTrue(profileTab.isSelected)

        mapTab.tap()
        XCTAssertTrue(mapTab.isSelected)

        profileTab.tap()

        let settingsButton = app.descendants(matching: .any)[
            "profile.settings"
        ]
        XCTAssertTrue(
            settingsButton.waitForExistence(timeout: 5),
            "Profile must expose Settings from the navigation bar."
        )
        settingsButton.tap()

        let signOutButton = app.descendants(matching: .any)[
            "settings.signOut"
        ]
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5))
        signOutButton.tap()

        let confirmSignOutButton = app.descendants(matching: .any)[
            "settings.signOut.confirm"
        ]
        XCTAssertTrue(
            confirmSignOutButton.waitForExistence(timeout: 5)
        )
        confirmSignOutButton.tap()

        XCTAssertTrue(
            app.buttons["Sign In"].waitForExistence(timeout: 15),
            "Signing out must return to the authentication screen."
        )
    }

    // MARK: - Helpers

    private func tabButton(
        title: String,
        identifier: String
    ) -> XCUIElement {
        app.tabBars.buttons
            .matching(
                NSPredicate(
                    format: "label == %@ OR identifier == %@",
                    title,
                    identifier
                )
            )
            .firstMatch
    }

    private func dismissPasswordSavePromptIfPresent(
        timeout: TimeInterval
    ) {
        let notNowButton = app.buttons["Not Now"]

        if notNowButton.waitForExistence(timeout: timeout) {
            notNowButton.tap()
        }
    }

    private func signOutIfNeeded() {
        let signInButton = app.buttons["Sign In"]

        if signInButton.waitForExistence(timeout: 3) {
            return
        }

        let profileTab = tabButton(
            title: "Profile",
            identifier: "person.crop.circle"
        )

        guard profileTab.waitForExistence(timeout: 10) else {
            return
        }

        profileTab.tap()

        let settingsButton = app.descendants(matching: .any)[
            "profile.settings"
        ]

        guard settingsButton.waitForExistence(timeout: 5) else {
            return
        }

        settingsButton.tap()

        let signOutButton = app.descendants(matching: .any)[
            "settings.signOut"
        ]

        guard signOutButton.waitForExistence(timeout: 5) else {
            return
        }

        signOutButton.tap()

        let confirmSignOutButton = app.descendants(matching: .any)[
            "settings.signOut.confirm"
        ]

        guard confirmSignOutButton.waitForExistence(timeout: 5) else {
            return
        }

        confirmSignOutButton.tap()
        _ = signInButton.waitForExistence(timeout: 15)
    }

    private func scrollToHittable(
        _ element: XCUIElement
    ) -> Bool {
        for _ in 0..<8 {
            if element.isHittable {
                return true
            }

            app.swipeUp()
        }

        return element.isHittable
    }
}
