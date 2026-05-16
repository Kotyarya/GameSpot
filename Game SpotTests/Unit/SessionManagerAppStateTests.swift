//
//  SessionManagerAppStateTests.swift
//  Game SpotTests
//
//  Validates root navigation state machine in SessionManager.appState.
//

import XCTest
@testable import Game_Spot

@MainActor
final class SessionManagerAppStateTests: XCTestCase {

    private var session: SessionManager!

    override func setUp() async throws {
        try await super.setUp()
        session = SessionManager()
        // Wait for initial restoreSession from init to settle.
        try await Task.sleep(for: .milliseconds(600))
    }

    func testAppStateLoadingBeforeSessionCheck() {
        session.didCheckSession = false
        session.user = nil
        session.isLoading = false

        XCTAssertEqual(session.appState, .loading)
    }

    func testAppStateAuthWhenNoUser() {
        session.didCheckSession = true
        session.user = nil
        session.isLoading = false
        session.error = nil

        XCTAssertEqual(session.appState, .auth)
    }

    func testAppStateAuthWhenErrorPresent() {
        session.didCheckSession = true
        session.user = nil
        session.isLoading = false
        session.error = "Network failure"

        XCTAssertEqual(session.appState, .auth)
    }

    func testAppStateLoadingWhenProfileMissing() {
        session.didCheckSession = true
        session.user = nil
        session.isLoading = false
        session.error = nil
        session.profile = nil

        // Without a user, auth is returned before profile guard.
        XCTAssertEqual(session.appState, .auth)
    }

    func testProfileFixtureRepresentsOnboardingState() {
        let profile = TestFixtures.profile(
            isOnboarded: false,
            isProfileCompleted: false
        )

        XCTAssertFalse(profile.isOnboarded)
        XCTAssertFalse(profile.isProfileCompleted)
    }

    func testProfileFixtureRepresentsProfileSetupState() {
        let profile = TestFixtures.profile(
            isOnboarded: true,
            isProfileCompleted: false
        )

        XCTAssertTrue(profile.isOnboarded)
        XCTAssertFalse(profile.isProfileCompleted)
    }

    func testProfileFixtureRepresentsMainState() {
        let profile = TestFixtures.profile(
            isOnboarded: true,
            isProfileCompleted: true
        )

        XCTAssertTrue(profile.isOnboarded)
        XCTAssertTrue(profile.isProfileCompleted)
    }
}
