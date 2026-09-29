import XCTest
@testable import Game_Spot

@MainActor
final class AccountDeletionViewModelTests: XCTestCase {

    func testDeleteAccountReturnsSuccessAfterServerConfirmation() async {
        let viewModel = AccountDeletionViewModel(
            service: AccountDeletionServiceMock(result: .success(()))
        )

        let deleted = await viewModel.deleteAccount()

        XCTAssertTrue(deleted)
        XCTAssertFalse(viewModel.isDeleting)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteAccountKeepsFailureVisible() async {
        let viewModel = AccountDeletionViewModel(
            service: AccountDeletionServiceMock(
                result: .failure(AccountDeletionTestError.failed)
            )
        )

        let deleted = await viewModel.deleteAccount()

        XCTAssertFalse(deleted)
        XCTAssertFalse(viewModel.isDeleting)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

@MainActor
private struct AccountDeletionServiceMock: AccountDeleting {
    let result: Result<Void, Error>

    func deleteAccount() async throws {
        try result.get()
    }
}

private enum AccountDeletionTestError: Error {
    case failed
}
