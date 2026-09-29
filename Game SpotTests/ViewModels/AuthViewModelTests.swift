import XCTest
@testable import Game_Spot

@MainActor
final class AuthViewModelTests: XCTestCase {

    func testIsValidRequiresNonEmptyEmail() {
        let viewModel = makeViewModel()
        viewModel.email = ""
        viewModel.password = "abcdef"

        XCTAssertFalse(viewModel.isValid)
    }

    func testIsValidRequiresMinimumPasswordLength() {
        let viewModel = makeViewModel()
        viewModel.email = "player@example.com"
        viewModel.password = "12345"

        XCTAssertFalse(viewModel.isValid)

        viewModel.password = "123456"
        XCTAssertTrue(viewModel.isValid)
    }

    func testInitialPublishedValues() {
        let viewModel = makeViewModel()

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.statusMessage)
        XCTAssertNil(viewModel.pendingConfirmationEmail)
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
    }

    func testSuccessfulSignInRefreshesSession() async {
        let service = AuthServiceStub()
        let session = SessionRefreshingStub()
        let viewModel = makeViewModel(service: service)
        viewModel.email = "player@example.com"
        viewModel.password = "valid-password"

        await viewModel.signIn(session: session).value

        XCTAssertEqual(service.receivedSignInEmail, "player@example.com")
        XCTAssertEqual(service.receivedSignInPassword, "valid-password")
        XCTAssertEqual(session.refreshCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFailedSignInShowsErrorWithoutRefreshingSession() async {
        let service = AuthServiceStub(signInError: AuthTestError.rejected)
        let session = SessionRefreshingStub()
        let viewModel = makeViewModel(service: service)
        viewModel.email = "player@example.com"
        viewModel.password = "wrong-password"

        await viewModel.signIn(session: session).value

        XCTAssertEqual(session.refreshCallCount, 0)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Couldn’t sign in. Check your details and connection, then try again."
        )
        XCTAssertFalse(viewModel.isLoading)
    }

    func testSignInKeepsLoadingVisibleUntilServiceCompletes() async {
        let service = SuspendedAuthServiceStub()
        let session = SessionRefreshingStub()
        let viewModel = makeViewModel(service: service)

        let task = viewModel.signIn(session: session)

        while !service.isSignInSuspended {
            await Task.yield()
        }

        XCTAssertTrue(viewModel.isLoading)

        service.resumeSignIn()
        await task.value

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(session.refreshCallCount, 1)
    }

    func testSignUpWithSessionRefreshesUser() async {
        let service = AuthServiceStub(
            signUpResult: .signedIn
        )
        let session = SessionRefreshingStub()
        let viewModel = makeViewModel(service: service)
        viewModel.email = " Player@Example.com "
        viewModel.password = "Password1"

        await viewModel.signUp(session: session).value

        XCTAssertEqual(service.receivedSignUpEmail, "player@example.com")
        XCTAssertEqual(session.refreshCallCount, 1)
        XCTAssertNil(viewModel.pendingConfirmationEmail)
    }

    func testSignUpWithoutSessionShowsEmailConfirmation() async {
        let service = AuthServiceStub(
            signUpResult: .confirmationRequired(
                email: "player@example.com"
            )
        )
        let session = SessionRefreshingStub()
        let viewModel = makeViewModel(service: service)
        viewModel.email = "player@example.com"
        viewModel.password = "Password1"

        await viewModel.signUp(session: session).value

        XCTAssertEqual(session.refreshCallCount, 0)
        XCTAssertEqual(
            viewModel.pendingConfirmationEmail,
            "player@example.com"
        )
    }

    func testResendConfirmationKeepsGenericSuccessState() async {
        let service = AuthServiceStub(
            signUpResult: .confirmationRequired(
                email: "player@example.com"
            )
        )
        let session = SessionRefreshingStub()
        let viewModel = makeViewModel(service: service)
        viewModel.email = "player@example.com"
        viewModel.password = "Password1"

        await viewModel.signUp(session: session).value
        await viewModel.resendSignUpConfirmation().value

        XCTAssertEqual(
            service.receivedResendEmail,
            "player@example.com"
        )
        XCTAssertEqual(
            viewModel.statusMessage,
            "Confirmation email sent. Open the link on this device."
        )
        XCTAssertNil(viewModel.errorMessage)
    }

    private func makeViewModel(
        service: (any AuthServing)? = nil
    ) -> AuthViewModel {

        AuthViewModel(
            service: service ?? AuthServiceStub()
        )
    }
}

@MainActor
private final class AuthServiceStub: AuthServing {

    private let signInError: Error?
    private let signUpResult: AuthSignUpResult
    private(set) var receivedSignInEmail: String?
    private(set) var receivedSignInPassword: String?
    private(set) var receivedSignUpEmail: String?
    private(set) var receivedResendEmail: String?

    init(
        signInError: Error? = nil,
        signUpResult: AuthSignUpResult = .signedIn
    ) {
        self.signInError = signInError
        self.signUpResult = signUpResult
    }

    func signUp(
        email: String,
        password: String
    ) async throws -> AuthSignUpResult {
        receivedSignUpEmail = email
        return signUpResult
    }

    func signIn(
        email: String,
        password: String
    ) async throws {

        receivedSignInEmail = email
        receivedSignInPassword = password

        if let signInError {
            throw signInError
        }
    }

    func resendSignUpConfirmation(
        email: String
    ) async throws {
        receivedResendEmail = email
    }
}

@MainActor
private final class SuspendedAuthServiceStub: AuthServing {

    private var signInContinuation: CheckedContinuation<Void, Never>?
    private(set) var isSignInSuspended = false

    func signUp(
        email: String,
        password: String
    ) async throws -> AuthSignUpResult {
        .signedIn
    }

    func signIn(
        email: String,
        password: String
    ) async throws {

        isSignInSuspended = true

        await withCheckedContinuation { continuation in
            signInContinuation = continuation
        }
    }

    func resumeSignIn() {
        signInContinuation?.resume()
        signInContinuation = nil
    }

    func resendSignUpConfirmation(
        email: String
    ) async throws {}
}

@MainActor
private final class SessionRefreshingStub: SessionRefreshing {

    private(set) var refreshCallCount = 0

    func refreshUser() {
        refreshCallCount += 1
    }
}

private enum AuthTestError: LocalizedError {

    case rejected

    var errorDescription: String? {
        "Invalid credentials"
    }
}
