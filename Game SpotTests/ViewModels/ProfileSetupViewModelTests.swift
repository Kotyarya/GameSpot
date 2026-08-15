import XCTest
import UIKit
@testable import Game_Spot

@MainActor
final class ProfileSetupViewModelTests: XCTestCase {

    func testPartialProfileFailureCanBeRetriedAfterAvatarUpload() async throws {
        let profileService = ProfileSetupServiceStub(
            completionResults: [
                .failure(ProfileSetupTestError.failed),
                .success(())
            ]
        )
        let avatarStorage = AvatarStorageStub()
        let viewModel = makeViewModel(
            profileService: profileService,
            avatarStorage: avatarStorage
        )

        configureValidInput(viewModel)

        do {
            try await viewModel.submit(userId: TestFixtures.userId)
            XCTFail("The first profile update should fail")
        } catch {
            XCTAssertEqual(
                error.localizedDescription,
                ProfileSetupTestError.failed.localizedDescription
            )
        }

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Couldn’t save your profile. Please try again."
        )
        XCTAssertEqual(avatarStorage.uploadCallCount, 1)
        XCTAssertEqual(profileService.completionCallCount, 1)

        try await viewModel.submit(userId: TestFixtures.userId)

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(avatarStorage.uploadCallCount, 2)
        XCTAssertEqual(profileService.completionCallCount, 2)
        XCTAssertEqual(
            profileService.receivedAvatarURLs.last,
            AvatarStorageStub.avatarURL.absoluteString
        )
    }

    func testSubmitWithoutAvatarCompletesProfileWithoutUpload() async throws {
        let profileService = ProfileSetupServiceStub()
        let avatarStorage = AvatarStorageStub()
        let viewModel = makeViewModel(
            profileService: profileService,
            avatarStorage: avatarStorage
        )

        viewModel.username = "testuser"
        viewModel.isUsernameAvailable = true
        viewModel.selectedSport = TestFixtures.sport()

        try await viewModel.submit(userId: TestFixtures.userId)

        XCTAssertEqual(avatarStorage.uploadCallCount, 0)
        XCTAssertEqual(profileService.receivedAvatarURLs, [nil])
    }

    func testRemovingAvatarAfterPartialFailureCleansUpUploadedObject() async throws {
        let profileService = ProfileSetupServiceStub(
            completionResults: [
                .failure(ProfileSetupTestError.failed),
                .success(())
            ]
        )
        let avatarStorage = AvatarStorageStub()
        let viewModel = makeViewModel(
            profileService: profileService,
            avatarStorage: avatarStorage
        )

        configureValidInput(viewModel)

        do {
            try await viewModel.submit(userId: TestFixtures.userId)
        } catch {
            // Expected partial failure after the upload.
        }

        viewModel.avatarImage = nil
        try await viewModel.submit(userId: TestFixtures.userId)

        XCTAssertEqual(avatarStorage.uploadCallCount, 1)
        XCTAssertEqual(avatarStorage.removeCallCount, 1)
        XCTAssertEqual(
            profileService.receivedAvatarURLs,
            [AvatarStorageStub.avatarURL.absoluteString, nil]
        )
    }

    private func makeViewModel(
        profileService: ProfileSetupServiceStub,
        avatarStorage: AvatarStorageStub
    ) -> ProfileSetupViewModel {

        ProfileSetupViewModel(
            profileService: profileService,
            sportService: SportServiceStub(),
            avatarStorage: avatarStorage,
            minimumLoadingDuration: 0
        )
    }

    private func configureValidInput(
        _ viewModel: ProfileSetupViewModel
    ) {

        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: 20, height: 20)
        )

        viewModel.username = "testuser"
        viewModel.isUsernameAvailable = true
        viewModel.selectedSport = TestFixtures.sport()
        viewModel.avatarImage = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
    }
}

@MainActor
private final class ProfileSetupServiceStub: ProfileSetupServing {

    private var completionResults: [Result<Void, Error>]
    private(set) var completionCallCount = 0
    private(set) var receivedAvatarURLs: [String?] = []

    init(
        completionResults: [Result<Void, Error>] = [.success(())]
    ) {
        self.completionResults = completionResults
    }

    func isUsernameAvailable(
        _ username: String
    ) async throws -> Bool {
        true
    }

    func completeProfile(
        userId: UUID,
        username: String,
        avatarUrl: String?,
        sportId: UUID
    ) async throws {

        completionCallCount += 1
        receivedAvatarURLs.append(avatarUrl)

        guard !completionResults.isEmpty else {
            return
        }

        try completionResults.removeFirst().get()
    }
}

@MainActor
private final class AvatarStorageStub: AvatarStoring {

    static let avatarURL = URL(
        string: "https://example.com/avatar.jpg?v=1"
    )!

    private(set) var uploadCallCount = 0
    private(set) var removeCallCount = 0

    func uploadAvatar(
        _ image: UIImage,
        userId: UUID
    ) async throws -> URL {

        uploadCallCount += 1
        return Self.avatarURL
    }

    func removeAvatar(userId: UUID) async throws {
        removeCallCount += 1
    }
}

private final class SportServiceStub: SportFetching, @unchecked Sendable {

    func fetchSports() async throws -> [Sport] {
        [TestFixtures.sport()]
    }
}

private enum ProfileSetupTestError: LocalizedError {

    case failed

    var errorDescription: String? {
        "Profile update failed"
    }
}
