import XCTest
import UIKit
@testable import Game_Spot

@MainActor
final class ProfileViewModelTests: XCTestCase {

    func testInitialStateShowsLoading() {
        let viewModel = makeViewModel()

        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.profile)
        XCTAssertTrue(viewModel.stats.isEmpty)
        XCTAssertTrue(viewModel.recentMatches.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.hasLoadedOnce)
    }

    func testLoadPublishesProfileAndSubscribes() async {
        let service = ProfileServiceStub()
        let realtime = ProfileRealtimeStub()
        let viewModel = makeViewModel(
            service: service,
            realtime: realtime
        )

        await viewModel.load(userId: TestFixtures.userId)

        XCTAssertEqual(viewModel.profile?.id, TestFixtures.userId)
        XCTAssertTrue(viewModel.stats.isEmpty)
        XCTAssertTrue(viewModel.recentMatches.isEmpty)
        XCTAssertTrue(viewModel.hasLoadedOnce)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(service.profileCallCount, 1)
        XCTAssertEqual(service.statsCallCount, 1)
        XCTAssertEqual(service.matchesCallCount, 1)
        XCTAssertEqual(realtime.receivedUserIds, [TestFixtures.userId])
    }

    func testLoadFailureStopsLoadingWithoutSubscription() async {
        let service = ProfileServiceStub(
            profileResult: .failure(ProfileTestError.failed)
        )
        let realtime = ProfileRealtimeStub()
        let viewModel = makeViewModel(
            service: service,
            realtime: realtime
        )

        await viewModel.load(userId: TestFixtures.userId)

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasLoadedOnce)
        XCTAssertEqual(
            viewModel.errorMessage,
            ProfileTestError.failed.localizedDescription
        )
        XCTAssertTrue(realtime.receivedUserIds.isEmpty)
    }

    func testLoadSkipsDuplicateRequestForSameUser() async {
        let service = ProfileServiceStub()
        let realtime = ProfileRealtimeStub()
        let viewModel = makeViewModel(
            service: service,
            realtime: realtime
        )

        await viewModel.load(userId: TestFixtures.userId)
        await viewModel.load(userId: TestFixtures.userId)

        XCTAssertEqual(service.profileCallCount, 1)
        XCTAssertEqual(service.statsCallCount, 1)
        XCTAssertEqual(service.matchesCallCount, 1)
        XCTAssertEqual(realtime.receivedUserIds.count, 1)
    }

    func testCancelledLoadAlwaysStopsLoading() async {
        let service = CancellingProfileServiceStub()
        let viewModel = makeViewModel(service: service)

        let task = Task {
            await viewModel.load(userId: TestFixtures.userId)
        }

        while !service.isFetchingProfile {
            await Task.yield()
        }

        task.cancel()
        await task.value

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.hasLoadedOnce)
    }

    func testAvatarReplacementCanRetryAfterProfileUpdateFailure() async {
        let storage = ProfileAvatarStorageStub()
        let updater = ProfileAvatarUpdaterStub(
            results: [
                .failure(ProfileTestError.failed),
                .success(())
            ]
        )
        let viewModel = makeViewModel(
            avatarStorage: storage,
            avatarUpdater: updater
        )

        await viewModel.load(userId: TestFixtures.userId)

        let firstResult = await viewModel.replaceAvatar(
            with: testImage(),
            userId: TestFixtures.userId
        )

        XCTAssertFalse(firstResult)
        XCTAssertEqual(storage.uploadCallCount, 1)
        XCTAssertEqual(updater.receivedAvatarURLs.count, 1)
        XCTAssertNotNil(viewModel.avatarErrorMessage)

        let retryResult = await viewModel.replaceAvatar(
            with: testImage(),
            userId: TestFixtures.userId
        )

        XCTAssertTrue(retryResult)
        XCTAssertEqual(storage.uploadCallCount, 2)
        XCTAssertEqual(updater.receivedAvatarURLs.count, 2)
        XCTAssertEqual(
            viewModel.profile?.avatarUrl,
            ProfileAvatarStorageStub.avatarURL.absoluteString
        )
        XCTAssertNil(viewModel.avatarErrorMessage)
    }

    func testAvatarRemovalDeletesObjectAndClearsProfileURL() async {
        let service = ProfileServiceStub(
            profileResult: .success(
                TestFixtures.profile(
                    avatarUrl: "https://example.com/old-avatar.jpg"
                )
            )
        )
        let storage = ProfileAvatarStorageStub()
        let updater = ProfileAvatarUpdaterStub()
        let viewModel = makeViewModel(
            service: service,
            avatarStorage: storage,
            avatarUpdater: updater
        )

        await viewModel.load(userId: TestFixtures.userId)
        let result = await viewModel.removeAvatar(
            userId: TestFixtures.userId
        )

        XCTAssertTrue(result)
        XCTAssertEqual(storage.removeCallCount, 1)
        XCTAssertEqual(updater.receivedAvatarURLs, [nil])
        XCTAssertNil(viewModel.profile?.avatarUrl)
        XCTAssertNil(viewModel.avatarErrorMessage)
    }

    private func makeViewModel(
        service: (any ProfileFetching)? = nil,
        realtime: (any ProfileRealtimeSubscribing)? = nil,
        avatarStorage: (any AvatarStoring)? = nil,
        avatarUpdater: (any ProfileAvatarUpdating)? = nil
    ) -> ProfileViewModel {

        ProfileViewModel(
            service: service ?? ProfileServiceStub(),
            realtime: realtime ?? ProfileRealtimeStub(),
            avatarStorage: avatarStorage ?? ProfileAvatarStorageStub(),
            avatarUpdater: avatarUpdater ?? ProfileAvatarUpdaterStub(),
            minimumLoadingDuration: 0
        )
    }

    private func testImage() -> UIImage {

        UIGraphicsImageRenderer(
            size: CGSize(width: 10, height: 10)
        ).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }
}

@MainActor
private class ProfileServiceStub: ProfileFetching {

    private let profileResult: Result<Profile, Error>
    private(set) var profileCallCount = 0
    private(set) var statsCallCount = 0
    private(set) var matchesCallCount = 0

    init(
        profileResult: Result<Profile, Error> = .success(TestFixtures.profile())
    ) {

        self.profileResult = profileResult
    }

    func fetchProfile(
        userId: UUID
    ) async throws -> Profile {

        profileCallCount += 1
        return try profileResult.get()
    }

    func fetchUserStats(
        userId: UUID
    ) async throws -> [UserSportStats] {

        statsCallCount += 1
        return []
    }

    func getRecentMatches() async throws -> [RecentMatch] {
        matchesCallCount += 1
        return []
    }
}

@MainActor
private final class CancellingProfileServiceStub: ProfileServiceStub {

    private(set) var isFetchingProfile = false

    override func fetchProfile(
        userId: UUID
    ) async throws -> Profile {

        isFetchingProfile = true
        try await Task.sleep(for: .seconds(60))
        throw CancellationError()
    }
}

@MainActor
private final class ProfileRealtimeStub: ProfileRealtimeSubscribing {

    private(set) var receivedUserIds: [UUID] = []

    func subscribe(
        userId: UUID,
        onProfileChange: @escaping @MainActor @Sendable (Profile) async -> Void,
        onStatsChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws {

        receivedUserIds.append(userId)
    }

    func unsubscribe() async {}
}

@MainActor
private final class ProfileAvatarStorageStub: AvatarStoring {

    static let avatarURL = URL(
        string: "https://example.com/avatar.jpg?v=2"
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

@MainActor
private final class ProfileAvatarUpdaterStub: ProfileAvatarUpdating {

    private var results: [Result<Void, Error>]
    private(set) var receivedAvatarURLs: [String?] = []

    init(
        results: [Result<Void, Error>] = [.success(())]
    ) {
        self.results = results
    }

    func updateAvatar(
        userId: UUID,
        avatarUrl: String?
    ) async throws {

        receivedAvatarURLs.append(avatarUrl)

        guard !results.isEmpty else {
            return
        }

        try results.removeFirst().get()
    }
}

private enum ProfileTestError: LocalizedError {

    case failed

    var errorDescription: String? {
        "Profile request failed"
    }
}
