import XCTest
import UIKit

final class Task80ProfileUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func testProfileSettingsReportAndBlockJourney() throws {

        let environment = ProcessInfo.processInfo.environment

        guard
            let email = environment["GAMESPOT_UI_TEST_EMAIL"],
            !email.isEmpty,
            let password = environment["GAMESPOT_UI_TEST_PASSWORD"],
            !password.isEmpty,
            let otherUserID = environment["TASK80_OTHER_USER_ID"],
            !otherUserID.isEmpty
        else {
            throw XCTSkip(
                "Set TASK-80 account credentials and the other user ID."
            )
        }

        app.launch()
        signOutIfNeeded()
        signIn(email: email, password: password)

        openTask80Game(otherUserID: otherUserID)
        verifyPublicProfileAndBlock(otherUserID: otherUserID)
        verifyOwnProfileAndSettings()
        signOutFromSettings()
    }

    private func signIn(
        email: String,
        password: String
    ) {

        let emailField = app.textFields["Enter your email"]
        let passwordField = app.secureTextFields["Enter your password"]

        XCTAssertTrue(emailField.waitForExistence(timeout: 15))
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))

        emailField.tap()
        emailField.typeText(email)
        XCTAssertEqual(
            emailField.value as? String,
            email,
            "The email field did not receive the expected value."
        )

        paste(password, into: passwordField)

        app.buttons["Sign In"].tap()

        XCTAssertTrue(
            tabButton(
                title: "My Games",
                identifier: "sportscourt.fill"
            ).waitForExistence(timeout: 20)
        )

        dismissPasswordSavePromptIfPresent()
    }

    private func paste(
        _ value: String,
        into field: XCUIElement
    ) {

        UIPasteboard.general.string = value
        field.tap()
        field.press(forDuration: 1)

        let pasteButton = app.menuItems["Paste"]
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 5))
        pasteButton.tap()

        let allowPasteButton = app.buttons["Allow Paste"]
        if allowPasteButton.waitForExistence(timeout: 2) {
            allowPasteButton.tap()
        }

        UIPasteboard.general.string = nil
    }

    private func openTask80Game(
        otherUserID: String
    ) {

        let gamesTab = tabButton(
            title: "My Games",
            identifier: "sportscourt.fill"
        )
        activate(gamesTab)

        let gameButton = app.buttons.matching(
            NSPredicate(
                format: "label CONTAINS[c] %@",
                "Basketball"
            )
        ).firstMatch

        XCTAssertTrue(
            gameButton.waitForExistence(timeout: 15),
            "The TASK-80 game must appear in My Games."
        )
        gameButton.tap()

        let playerRow = app.descendants(matching: .any)[
            "gameDetails.player.\(otherUserID.uppercased())"
        ]

        XCTAssertTrue(
            playerRow.waitForExistence(timeout: 15),
            "The second account must appear in the game roster."
        )
        playerRow.tap()
    }

    private func verifyPublicProfileAndBlock(
        otherUserID: String
    ) {

        XCTAssertTrue(
            app.descendants(matching: .any)[
                "publicProfile.content"
            ].waitForExistence(timeout: 15)
        )
        XCTAssertFalse(app.buttons["profile.edit"].exists)
        XCTAssertFalse(app.buttons["profile.settings"].exists)

        openPublicProfileActions()
        menuButton(
            identifier: "publicProfile.report",
            label: "Report User"
        ).tap()

        XCTAssertTrue(
            app.buttons["report.submit"]
                .waitForExistence(timeout: 5)
        )
        app.buttons["report.submit"].tap()

        XCTAssertTrue(
            app.alerts["Report Submitted"]
                .waitForExistence(timeout: 10)
        )
        app.alerts["Report Submitted"].buttons["OK"].tap()

        openPublicProfileActions()
        menuButton(
            identifier: "publicProfile.block",
            label: "Block User"
        ).tap()

        let confirmBlock = app.buttons["Block User"]
        XCTAssertTrue(confirmBlock.waitForExistence(timeout: 5))
        confirmBlock.tap()

        let blockedRow = app.descendants(matching: .any)[
            "gameDetails.blockedPlayer.\(otherUserID.uppercased())"
        ]

        XCTAssertTrue(
            blockedRow.waitForExistence(timeout: 15),
            "A blocked participant must remain in the roster."
        )
        XCTAssertTrue(app.staticTexts["Blocked player"].exists)
        XCTAssertTrue(app.staticTexts["Blocked"].exists)
        XCTAssertFalse(app.staticTexts["task80bravo"].exists)
    }

    private func verifyOwnProfileAndSettings() {

        tabButton(
            title: "Profile",
            identifier: "person.crop.circle"
        ).tap()

        XCTAssertTrue(
            app.staticTexts["Overall Profile"]
                .waitForExistence(timeout: 15)
        )

        let editButton = app.buttons["profile.edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        XCTAssertEqual(editButton.label, "Edit")
        editButton.tap()

        XCTAssertEqual(editButton.label, "Done")
        XCTAssertTrue(
            app.descendants(matching: .any)[
                "profile.avatar.choose"
            ].waitForExistence(timeout: 5)
        )
        editButton.tap()

        let settingsButton = app.buttons["profile.settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        for identifier in [
            "settings.privacyPolicy",
            "settings.blockedUsers",
            "settings.support",
            "settings.about",
            "settings.signOut",
            "settings.deleteAccount"
        ] {
            XCTAssertTrue(
                app.descendants(matching: .any)[identifier]
                    .waitForExistence(timeout: 5),
                "Missing Settings item: \(identifier)"
            )
        }

        app.descendants(matching: .any)[
            "settings.blockedUsers"
        ].tap()
        XCTAssertTrue(
            app.staticTexts["task80bravo"]
                .waitForExistence(timeout: 10)
        )

        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.descendants(matching: .any)[
            "settings.deleteAccount"
        ].tap()
        let continueButton = app.buttons[
            "settings.deleteAccount.continue"
        ].firstMatch
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()

        XCTAssertTrue(
            app.buttons["Delete Forever"]
                .waitForExistence(timeout: 5)
        )
        app.alerts.firstMatch.buttons["Cancel"].tap()
    }

    private func signOutFromSettings() {

        app.descendants(matching: .any)[
            "settings.signOut"
        ].tap()

        let confirmSignOut = app.buttons[
            "settings.signOut.confirm"
        ].firstMatch
        XCTAssertTrue(confirmSignOut.waitForExistence(timeout: 5))
        confirmSignOut.tap()

        XCTAssertTrue(
            app.buttons["Sign In"].waitForExistence(timeout: 15)
        )
    }

    private func openPublicProfileActions() {

        let actions = app.buttons["publicProfile.actions"]
        XCTAssertTrue(actions.waitForExistence(timeout: 5))
        actions.tap()
    }

    private func menuButton(
        identifier: String,
        label: String
    ) -> XCUIElement {

        let identified = app.buttons[identifier]

        if identified.waitForExistence(timeout: 2) {
            return identified
        }

        return app.buttons[label]
    }

    private func signOutIfNeeded() {

        if app.buttons["Sign In"].waitForExistence(timeout: 3) {
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

        let settings = app.buttons["profile.settings"]

        guard settings.waitForExistence(timeout: 5) else {
            return
        }

        settings.tap()
        signOutFromSettings()
    }

    private func tabButton(
        title: String,
        identifier: String
    ) -> XCUIElement {

        let titledButton = app.tabBars.buttons[title]

        if titledButton.exists {
            return titledButton
        }

        return app.tabBars.buttons[identifier]
    }

    private func activate(
        _ tab: XCUIElement
    ) {

        for _ in 0..<3 {
            tab.tap()

            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(
                    format: "isSelected == true"
                ),
                object: tab
            )

            if XCTWaiter.wait(
                for: [selected],
                timeout: 3
            ) == .completed {
                return
            }
        }

        XCTFail("The requested tab did not become active.")
    }

    private func dismissPasswordSavePromptIfPresent() {

        let notNowButton = app.buttons["Not Now"]

        if notNowButton.waitForExistence(timeout: 3) {
            notNowButton.tap()
        }
    }
}
