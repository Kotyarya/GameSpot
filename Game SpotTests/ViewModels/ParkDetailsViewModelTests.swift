import XCTest
@testable import Game_Spot

@MainActor
final class ParkDetailsViewModelTests: XCTestCase {

    func testLoadPublishesDetails() async {
        let service = ParkDetailsServiceStub()
        let viewModel = ParkDetailsViewModel(service: service)

        await viewModel.load(parkId: TestFixtures.parkId)

        XCTAssertEqual(
            viewModel.details?.park.id,
            TestFixtures.parkId
        )
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadFailureCanRetryWithoutTechnicalDetails() async {
        let service = ParkDetailsServiceStub(
            detailsResults: [
                .failure(ParkDetailsTestError.secretBackendDetails),
                .success(Self.details)
            ]
        )
        let viewModel = ParkDetailsViewModel(service: service)

        await viewModel.load(parkId: TestFixtures.parkId)

        XCTAssertNil(viewModel.details)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Couldn’t load this park. Check your connection and try again."
        )
        XCTAssertFalse(
            viewModel.errorMessage?.contains("secret") == true
        )

        await viewModel.load(parkId: TestFixtures.parkId)

        XCTAssertNotNil(viewModel.details)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(service.detailsCallCount, 2)
    }

    func testRatingFailureStaysRetryable() async {
        let service = ParkDetailsServiceStub(
            ratingResults: [
                .failure(ParkDetailsTestError.secretBackendDetails),
                .success(())
            ]
        )
        let viewModel = ParkDetailsViewModel(service: service)

        let firstResult = await viewModel.submitRating(
            userId: TestFixtures.userId,
            parkId: TestFixtures.parkId,
            quality: 4,
            facilities: 5,
            activity: 3
        )

        XCTAssertFalse(firstResult)
        XCTAssertEqual(
            viewModel.ratingErrorMessage,
            "Couldn’t submit your rating. Check your connection and try again."
        )
        XCTAssertFalse(viewModel.isSubmittingRating)

        let retryResult = await viewModel.submitRating(
            userId: TestFixtures.userId,
            parkId: TestFixtures.parkId,
            quality: 4,
            facilities: 5,
            activity: 3
        )

        XCTAssertTrue(retryResult)
        XCTAssertTrue(viewModel.hasRated)
        XCTAssertNil(viewModel.ratingErrorMessage)
        XCTAssertEqual(service.ratingCallCount, 2)
    }

    func testOlderParkResponseCannotReplaceLatestSelection() async {
        let firstParkId = TestFixtures.parkId
        let secondParkId = UUID()
        let service = OutOfOrderParkDetailsServiceStub()
        let viewModel = ParkDetailsViewModel(service: service)

        let firstTask = Task {
            await viewModel.load(parkId: firstParkId)
        }

        while !service.requestedParkIds.contains(firstParkId) {
            await Task.yield()
        }

        let secondTask = Task {
            await viewModel.load(parkId: secondParkId)
        }

        while !service.requestedParkIds.contains(secondParkId) {
            await Task.yield()
        }

        service.resume(
            parkId: secondParkId,
            details: Self.details(parkId: secondParkId)
        )
        await secondTask.value

        service.resume(
            parkId: firstParkId,
            details: Self.details(parkId: firstParkId)
        )
        await firstTask.value

        XCTAssertEqual(viewModel.details?.park.id, secondParkId)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testOlderRatingCheckCannotUndoSuccessfulRating() async {
        let service = RatingRaceParkDetailsServiceStub()
        let viewModel = ParkDetailsViewModel(service: service)

        await viewModel.load(parkId: TestFixtures.parkId)

        let checkTask = Task {
            await viewModel.checkIfRated(
                userId: TestFixtures.userId,
                parkId: TestFixtures.parkId
            )
        }

        while !service.isCheckingRating {
            await Task.yield()
        }

        let didSubmit = await viewModel.submitRating(
            userId: TestFixtures.userId,
            parkId: TestFixtures.parkId,
            quality: 4,
            facilities: 5,
            activity: 3
        )

        service.resumeRatingCheck(with: false)
        await checkTask.value

        XCTAssertTrue(didSubmit)
        XCTAssertTrue(viewModel.hasRated)
    }

    fileprivate static func details(
        parkId: UUID
    ) -> ParkDetails {

        ParkDetails(
            park: Park(
                id: parkId,
                name: "Central Park",
                latitude: 50.45,
                longitude: 30.52,
                address: "Main Street",
                isActive: true,
                hasLighting: true
            ),
            sports: [TestFixtures.sport()],
            hours: [],
            images: [],
            rating: nil
        )
    }

    fileprivate static let details = details(
        parkId: TestFixtures.parkId
    )
}

@MainActor
private final class OutOfOrderParkDetailsServiceStub: ParkDetailsServing {

    private var continuations: [
        UUID: CheckedContinuation<ParkDetails, Error>
    ] = [:]

    private(set) var requestedParkIds: [UUID] = []

    func fetchParkDetails(
        parkId: UUID
    ) async throws -> ParkDetails {
        requestedParkIds.append(parkId)

        return try await withCheckedThrowingContinuation {
            continuations[parkId] = $0
        }
    }

    func ratePark(
        userId: UUID,
        parkId: UUID,
        quality: Int,
        facilities: Int,
        activity: Int
    ) async throws {}

    func hasUserRated(
        userId: UUID,
        parkId: UUID
    ) async throws -> Bool {
        false
    }

    func resume(
        parkId: UUID,
        details: ParkDetails
    ) {
        continuations.removeValue(forKey: parkId)?
            .resume(returning: details)
    }
}

@MainActor
private final class RatingRaceParkDetailsServiceStub: ParkDetailsServing {

    private var ratingCheckContinuation:
        CheckedContinuation<Bool, Error>?

    private(set) var isCheckingRating = false

    func fetchParkDetails(
        parkId: UUID
    ) async throws -> ParkDetails {
        ParkDetailsViewModelTests.details(
            parkId: parkId
        )
    }

    func ratePark(
        userId: UUID,
        parkId: UUID,
        quality: Int,
        facilities: Int,
        activity: Int
    ) async throws {}

    func hasUserRated(
        userId: UUID,
        parkId: UUID
    ) async throws -> Bool {
        isCheckingRating = true

        return try await withCheckedThrowingContinuation {
            ratingCheckContinuation = $0
        }
    }

    func resumeRatingCheck(
        with result: Bool
    ) {
        ratingCheckContinuation?.resume(returning: result)
        ratingCheckContinuation = nil
    }
}

@MainActor
private final class ParkDetailsServiceStub: ParkDetailsServing {

    private var detailsResults: [Result<ParkDetails, Error>]
    private var ratingResults: [Result<Void, Error>]

    private(set) var detailsCallCount = 0
    private(set) var ratingCallCount = 0

    init(
        detailsResults: [Result<ParkDetails, Error>]? = nil,
        ratingResults: [Result<Void, Error>] = [.success(())]
    ) {
        self.detailsResults = detailsResults
            ?? [.success(ParkDetailsViewModelTests.details)]
        self.ratingResults = ratingResults
    }

    func fetchParkDetails(
        parkId: UUID
    ) async throws -> ParkDetails {
        detailsCallCount += 1

        let result = detailsResults.count > 1
            ? detailsResults.removeFirst()
            : detailsResults[0]

        return try result.get()
    }

    func ratePark(
        userId: UUID,
        parkId: UUID,
        quality: Int,
        facilities: Int,
        activity: Int
    ) async throws {
        ratingCallCount += 1

        let result = ratingResults.count > 1
            ? ratingResults.removeFirst()
            : ratingResults[0]

        try result.get()
    }

    func hasUserRated(
        userId: UUID,
        parkId: UUID
    ) async throws -> Bool {
        false
    }
}

private enum ParkDetailsTestError: LocalizedError {

    case secretBackendDetails

    var errorDescription: String? {
        "secret backend details"
    }
}
