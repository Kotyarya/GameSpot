import XCTest

final class ContentStateFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testErrorStateExplainsProblemAndRetryRecovers() {
        launch(scenario: "error")

        XCTAssertTrue(
            app.staticTexts["Couldn’t Load Games"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts[
                "Check your connection and try again."
            ].exists
        )

        let retryButton = app.buttons["Try Again"]
        XCTAssertTrue(retryButton.exists)
        retryButton.tap()

        XCTAssertTrue(
            app.staticTexts["No Games Yet"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            app.staticTexts["Retry calls: 1"].exists
        )
    }

    func testSlowLoadShowsLoadingBeforeEmptyState() {
        launch(scenario: "slow")

        XCTAssertTrue(
            app.descendants(matching: .any)[
                "contentState.harness.loading"
            ].waitForExistence(timeout: 3)
        )

        XCTAssertTrue(
            app.staticTexts["No Games Yet"]
                .waitForExistence(timeout: 10)
        )
        XCTAssertTrue(
            app.staticTexts[
                "Explore a park and join your first game."
            ].exists
        )
    }

    private func launch(
        scenario: String
    ) {
        app.launchArguments = [
            "--ui-test-content-state=\(scenario)"
        ]
        app.launch()

        XCTAssertTrue(
            app.wait(
                for: .runningForeground,
                timeout: 10
            )
        )
    }
}
