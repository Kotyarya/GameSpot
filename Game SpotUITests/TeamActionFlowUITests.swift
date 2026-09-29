import XCTest

final class TeamActionFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testRepeatedJoinTapSubmitsOnceAndClosesSheet() {
        launch(scenario: "join")

        let joinButton = firstHittableButton(identifier: "team.alpha.join.0")

        tapTwice(at: joinButton)

        let count = app.staticTexts["team.harness.joinCalls"]
        XCTAssertTrue(
            count.waitForExistence(timeout: 5),
            app.debugDescription
        )
        waitForLabel("Join calls: 1", on: count)
    }

    func testRepeatedLeaveTapSubmitsOnceAndClosesSheet() {
        launch(scenario: "leave")

        let leaveButton = firstHittableButton(identifier: "team.leave")

        tapTwice(at: leaveButton)

        let count = app.staticTexts["team.harness.leaveCalls"]
        XCTAssertTrue(
            count.waitForExistence(timeout: 5),
            app.debugDescription
        )
        waitForLabel("Leave calls: 1", on: count)
    }

    func testJoinErrorStaysVisibleAndReenablesActions() {
        launch(scenario: "error")

        let joinButton = firstHittableButton(identifier: "team.alpha.join.0")

        tapTwice(at: joinButton)

        let errorBanner = app.staticTexts["team.error"]
        XCTAssertTrue(errorBanner.waitForExistence(timeout: 5))

        let enabledJoinButton = app.buttons["team.alpha.join.0"]
        XCTAssertTrue(enabledJoinButton.exists)
        XCTAssertTrue(enabledJoinButton.isEnabled)
    }

    private func launch(scenario: String) {
        app.launchArguments = [
            "--ui-test-team-sheet=\(scenario)"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let presentationFinished = expectation(
            description: "Team sheet presentation finished"
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            presentationFinished.fulfill()
        }
        wait(for: [presentationFinished], timeout: 1)
    }

    private func tapTwice(
        at element: XCUIElement
    ) {

        let frame = element.frame
        let coordinate = app.coordinate(
            withNormalizedOffset: CGVector(dx: 0, dy: 0)
        ).withOffset(
            CGVector(dx: frame.midX, dy: frame.midY)
        )

        element.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["team.submitting"]
                .waitForExistence(timeout: 2),
            app.debugDescription
        )

        coordinate.tap()
    }

    private func firstHittableButton(
        identifier: String
    ) -> XCUIElement {

        let buttons = app.buttons.matching(identifier: identifier)
        XCTAssertTrue(
            buttons.firstMatch.waitForExistence(timeout: 5),
            app.debugDescription
        )

        for index in 0..<buttons.count {
            let button = buttons.element(boundBy: index)

            if button.isHittable {
                return button
            }
        }

        XCTFail("No hittable button named \(identifier). \(app.debugDescription)")
        return buttons.firstMatch
    }

    private func waitForLabel(
        _ label: String,
        on element: XCUIElement
    ) {

        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", label),
            object: element
        )

        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5),
            .completed
        )
    }
}
