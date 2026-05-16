//
//  Game_SpotUITests.swift
//  Game SpotUITests
//
//  Application launch smoke tests.
//

import XCTest

final class Game_SpotUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsRootInterface() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let hasAuth = app.buttons["Sign In"].waitForExistence(timeout: 15)
        let hasTabs = app.tabBars.firstMatch.waitForExistence(timeout: 2)
        let hasLoading = app.staticTexts["Game Spot"].waitForExistence(timeout: 2)

        XCTAssertTrue(
            hasAuth || hasTabs || hasLoading,
            "App should show auth, main tabs, or loading screen after launch."
        )
    }
}
