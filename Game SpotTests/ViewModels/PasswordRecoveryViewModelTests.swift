import XCTest
@testable import Game_Spot

@MainActor
final class PasswordRecoveryViewModelTests: XCTestCase {

    func testResetRequestNormalizesEmailAndShowsGenericSuccess() async {
        let service = PasswordRecoveryServiceStub()
        let viewModel = PasswordResetRequestViewModel(
            email: " Player@Example.com ",
            service: service
        )

        await viewModel.requestReset().value

        XCTAssertEqual(
            service.requestedEmails,
            ["player@example.com"]
        )
        XCTAssertTrue(viewModel.didSendRequest)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testResetRequestFailureDoesNotExposeTechnicalError() async {
        let service = PasswordRecoveryServiceStub(
            requestError: PasswordRecoveryTestError.secretBackendMessage
        )
        let viewModel = PasswordResetRequestViewModel(
            email: "player@example.com",
            service: service
        )

        await viewModel.requestReset().value

        XCTAssertFalse(viewModel.didSendRequest)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Couldn’t send a reset email. Check your connection and try again."
        )
        XCTAssertFalse(
            viewModel.errorMessage?.contains("secret") == true
        )
    }

    func testPasswordUpdateRequiresSharedRulesAndMatchingValues() async {
        let service = PasswordRecoveryServiceStub()
        let viewModel = PasswordRecoveryViewModel(service: service)
        viewModel.password = "Password1"
        viewModel.confirmation = "Password2"

        let result = await viewModel.updatePassword()

        XCTAssertFalse(result)
        XCTAssertTrue(service.updatedPasswords.isEmpty)
    }

    func testSuccessfulPasswordUpdateCallsService() async {
        let service = PasswordRecoveryServiceStub()
        let viewModel = PasswordRecoveryViewModel(service: service)
        viewModel.password = "Password1"
        viewModel.confirmation = "Password1"

        let result = await viewModel.updatePassword()

        XCTAssertTrue(result)
        XCTAssertEqual(service.updatedPasswords, ["Password1"])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testPasswordUpdateFailureStaysOnRecoveryScreen() async {
        let service = PasswordRecoveryServiceStub(
            updateError: PasswordRecoveryTestError.secretBackendMessage
        )
        let viewModel = PasswordRecoveryViewModel(service: service)
        viewModel.password = "Password1"
        viewModel.confirmation = "Password1"

        let result = await viewModel.updatePassword()

        XCTAssertFalse(result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(
            viewModel.errorMessage?.contains("secret") == true
        )
        XCTAssertFalse(viewModel.isLoading)
    }
}

@MainActor
private final class PasswordRecoveryServiceStub: PasswordRecoveryServing {

    private let requestError: Error?
    private let updateError: Error?

    private(set) var requestedEmails: [String] = []
    private(set) var updatedPasswords: [String] = []

    init(
        requestError: Error? = nil,
        updateError: Error? = nil
    ) {
        self.requestError = requestError
        self.updateError = updateError
    }

    func requestPasswordReset(
        email: String
    ) async throws {
        requestedEmails.append(email)
        if let requestError {
            throw requestError
        }
    }

    func updatePassword(
        _ password: String
    ) async throws {
        updatedPasswords.append(password)
        if let updateError {
            throw updateError
        }
    }
}

private enum PasswordRecoveryTestError: LocalizedError {

    case secretBackendMessage

    var errorDescription: String? {
        "secret backend details"
    }
}
