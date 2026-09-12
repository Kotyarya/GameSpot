//
//  SessionManagerAppStateTests.swift
//  Game SpotTests
//
//  Validates root navigation state machine in SessionManager.appState.
//

import XCTest
import Supabase
@testable import Game_Spot

@MainActor
final class SessionManagerAppStateTests: XCTestCase {

    private var session: SessionManager!

    override func setUp() {
        super.setUp()
        session = SessionManager(
            restoreSessionOnInit: false
        )
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

    func testProfileLoadFailureShowsRecoverableAccountState() async {
        let user = User(
            id: TestFixtures.userId,
            appMetadata: [:],
            userMetadata: [:],
            aud: "authenticated",
            email: "player@example.com",
            createdAt: Date(),
            updatedAt: Date()
        )
        let failedSession = SessionManager(
            authService: SessionAuthServiceStub(
                currentUser: user
            ),
            profileService: FailingProfileServiceStub(),
            restoreSessionOnInit: false
        )

        await failedSession.restoreSession()

        XCTAssertTrue(failedSession.didCheckSession)
        XCTAssertEqual(failedSession.appState, .loadError)
        XCTAssertEqual(
            failedSession.error,
            "Couldn’t load your account. Check your connection and try again."
        )
        XCTAssertNil(failedSession.profile)
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

    func testFinishPasswordRecoveryClearsSessionAndShowsNotice() async {
        let authService = SessionAuthServiceStub()
        let recoverySession = SessionManager(
            authService: authService,
            restoreSessionOnInit: false
        )

        await recoverySession.finishPasswordRecovery()

        XCTAssertEqual(authService.signOutCallCount, 1)
        XCTAssertNil(recoverySession.user)
        XCTAssertNil(recoverySession.profile)
        XCTAssertTrue(recoverySession.didCheckSession)
        XCTAssertEqual(
            recoverySession.authNotice,
            "Password updated. Sign in with your new password."
        )
        XCTAssertEqual(recoverySession.appState, .auth)
    }
}

@MainActor
private final class SessionAuthServiceStub: SessionAuthServing {

    let currentUser: User?

    private(set) var signOutCallCount = 0

    init(
        currentUser: User? = nil
    ) {
        self.currentUser = currentUser
    }

    func signOut() async throws {
        signOutCallCount += 1
    }
}

@MainActor
private final class FailingProfileServiceStub: ProfileFetching {

    func fetchProfile(
        userId: UUID
    ) async throws -> Profile {
        throw SessionStateTestError.secretBackendFailure
    }

    func fetchUserStats(
        userId: UUID
    ) async throws -> [UserSportStats] {
        []
    }

    func getRecentMatches() async throws -> [RecentMatch] {
        []
    }
}

private enum SessionStateTestError: LocalizedError {

    case secretBackendFailure

    var errorDescription: String? {
        "secret backend failure"
    }
}
