import XCTest

final class LocationPermissionUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.resetAuthorizationStatus(for: .location)
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func testOnboardingLocationPromptExplainsForegroundUse() {
        app.launchArguments = [
            "--ui-test-location-permission"
        ]
        app.launch()

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(
            continueButton.waitForExistence(timeout: 10)
        )
        continueButton.tap()

        let springboard = XCUIApplication(
            bundleIdentifier: "com.apple.springboard"
        )
        let alert = springboard.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertTrue(
            alert.staticTexts[
                "Game Spot uses your location to show your position on the map and help you find nearby sports parks."
            ].exists
        )
    }
}
