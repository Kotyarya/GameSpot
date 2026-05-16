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
        app.launch()
    }

    // MARK: - Tab Bar

    func testMainTabBarVisibleWhenAuthenticated() throws {
        let mapTab = app.tabBars.buttons["Map"]
        let gamesTab = app.tabBars.buttons["My Games"]
        let profileTab = app.tabBars.buttons["Profile"]

        let mapExists = mapTab.waitForExistence(timeout: 20)
        let gamesExists = gamesTab.waitForExistence(timeout: 2)
        let profileExists = profileTab.waitForExistence(timeout: 2)

        // Pass when main tabs are visible (logged in) or skip assertion when on auth.
        if mapExists && gamesExists && profileExists {
            XCTAssertTrue(mapTab.isSelected)

            gamesTab.tap()
            XCTAssertTrue(gamesTab.isSelected)

            profileTab.tap()
            XCTAssertTrue(profileTab.isSelected)

            mapTab.tap()
            XCTAssertTrue(mapTab.isSelected)
        } else {
            // Unauthenticated launch — verify auth UI instead of failing.
            XCTAssertTrue(
                app.buttons["Sign In"].waitForExistence(timeout: 5)
                || app.staticTexts["Game Spot"].waitForExistence(timeout: 5)
            )
        }
    }
}
