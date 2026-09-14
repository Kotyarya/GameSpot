import XCTest
@testable import Game_Spot

@MainActor
final class UserSafetyViewModelTests: XCTestCase {

    func testSubmitReportPublishesSafeSuccessForNewReport() async {
        let service = UserSafetyServiceStub()
        let viewModel = UserSafetyViewModel(service: service)
        let reportedUserId = UUID()

        viewModel.selectedReason = .abusiveBehavior
        viewModel.reportDetails = "Repeated harassment"

        let submitted = await viewModel.submitReport(
            userId: reportedUserId
        )

        XCTAssertTrue(submitted)
        XCTAssertEqual(service.reportedUserId, reportedUserId)
        XCTAssertEqual(service.reportReason, .abusiveBehavior)
        XCTAssertEqual(service.reportDetails, "Repeated harassment")
        XCTAssertEqual(viewModel.reportDetails, "")
        XCTAssertNotNil(viewModel.successMessage)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDuplicateReportStillPublishesSafeSuccess() async {
        let service = UserSafetyServiceStub(
            submitResult: .success(false)
        )
        let viewModel = UserSafetyViewModel(service: service)

        let submitted = await viewModel.submitReport(
            userId: UUID()
        )

        XCTAssertTrue(submitted)
        XCTAssertNotNil(viewModel.successMessage)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testReportDetailsOverLimitNeverReachService() async {
        let service = UserSafetyServiceStub()
        let viewModel = UserSafetyViewModel(service: service)

        viewModel.reportDetails = String(
            repeating: "a",
            count: 501
        )

        let submitted = await viewModel.submitReport(
            userId: UUID()
        )

        XCTAssertFalse(submitted)
        XCTAssertEqual(service.submitCallCount, 0)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Report details must be 500 characters or fewer."
        )
    }

    func testReportFailureDoesNotExposeBackendError() async {
        let service = UserSafetyServiceStub(
            submitResult: .failure(
                UserSafetyTestError.secretBackendDetails
            )
        )
        let viewModel = UserSafetyViewModel(service: service)

        let submitted = await viewModel.submitReport(
            userId: UUID()
        )

        XCTAssertFalse(submitted)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Couldn’t submit the report. Please try again."
        )
        XCTAssertFalse(
            viewModel.errorMessage?.contains("secret") == true
        )
    }

    func testBlockSendsServerMutation() async {
        let service = UserSafetyServiceStub()
        let viewModel = UserSafetyViewModel(service: service)
        let blockedUserId = UUID()

        let blocked = await viewModel.block(
            userId: blockedUserId
        )

        XCTAssertTrue(blocked)
        XCTAssertEqual(service.blockedUserId, blockedUserId)
        XCTAssertEqual(service.requestedBlockState, true)
        XCTAssertEqual(viewModel.successMessage, "User blocked.")
    }

    func testBlockedUsersLoadAndUnblock() async {
        let blockedUser = BlockedUser(
            blockedId: UUID(),
            blockedUsername: "blocked_player",
            blockedAvatarUrl: nil,
            createdAt: Date()
        )
        let service = UserSafetyServiceStub(
            blockedUsersResult: .success([blockedUser])
        )
        let viewModel = BlockedUsersViewModel(service: service)

        await viewModel.load()

        XCTAssertEqual(viewModel.users, [blockedUser])

        await viewModel.unblock(blockedUser)

        XCTAssertTrue(viewModel.users.isEmpty)
        XCTAssertEqual(service.blockedUserId, blockedUser.id)
        XCTAssertEqual(service.requestedBlockState, false)
    }

    func testFailedUnblockKeepsUserVisible() async {
        let blockedUser = BlockedUser(
            blockedId: UUID(),
            blockedUsername: "blocked_player",
            blockedAvatarUrl: nil,
            createdAt: Date()
        )
        let service = UserSafetyServiceStub(
            blockResult: .failure(
                UserSafetyTestError.secretBackendDetails
            ),
            blockedUsersResult: .success([blockedUser])
        )
        let viewModel = BlockedUsersViewModel(service: service)

        await viewModel.load()
        await viewModel.unblock(blockedUser)

        XCTAssertEqual(viewModel.users, [blockedUser])
        XCTAssertEqual(
            viewModel.errorMessage,
            "Couldn’t unblock this user. Please try again."
        )
    }
}

@MainActor
private final class UserSafetyServiceStub: UserSafetyServing {

    var submitResult: Result<Bool, Error>
    var blockResult: Result<Void, Error>
    var blockedUsersResult: Result<[BlockedUser], Error>

    private(set) var submitCallCount = 0
    private(set) var reportedUserId: UUID?
    private(set) var reportReason: ReportReason?
    private(set) var reportDetails: String?
    private(set) var blockedUserId: UUID?
    private(set) var requestedBlockState: Bool?

    init(
        submitResult: Result<Bool, Error> = .success(true),
        blockResult: Result<Void, Error> = .success(()),
        blockedUsersResult: Result<[BlockedUser], Error> = .success([])
    ) {
        self.submitResult = submitResult
        self.blockResult = blockResult
        self.blockedUsersResult = blockedUsersResult
    }

    func submitReport(
        userId: UUID,
        reason: ReportReason,
        details: String?
    ) async throws -> Bool {

        submitCallCount += 1
        reportedUserId = userId
        reportReason = reason
        reportDetails = details

        return try submitResult.get()
    }

    func setBlocked(
        userId: UUID,
        isBlocked: Bool
    ) async throws {

        blockedUserId = userId
        requestedBlockState = isBlocked

        try blockResult.get()
    }

    func fetchBlockedUsers() async throws -> [BlockedUser] {
        try blockedUsersResult.get()
    }
}

private enum UserSafetyTestError: Error {
    case secretBackendDetails
}
