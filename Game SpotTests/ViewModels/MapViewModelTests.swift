import XCTest
@testable import Game_Spot

@MainActor
final class MapViewModelTests: XCTestCase {

    func testInitialStateHasNoContentOrError() {
        let viewModel = MapViewModel(
            service: ParksServiceStub()
        )

        XCTAssertTrue(viewModel.parks.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadPublishesParks() async {
        let park = Self.park
        let viewModel = MapViewModel(
            service: ParksServiceStub(
                results: [.success([park])]
            )
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.parks, [park])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testOfflineFailureShowsSafeRetryableMessage() async {
        let service = ParksServiceStub(
            results: [
                .failure(MapViewModelTestError.secretNetworkDetails),
                .success([Self.park])
            ]
        )
        let viewModel = MapViewModel(service: service)

        await viewModel.load()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Couldn’t load parks. Check your connection and try again."
        )
        XCTAssertFalse(
            viewModel.errorMessage?.contains("secret") == true
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.parks, [Self.park])
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(service.callCount, 2)
    }

    func testSlowLoadKeepsLoadingVisibleUntilCompletion() async {
        let service = SuspendedParksServiceStub()
        let viewModel = MapViewModel(service: service)

        let task = Task {
            await viewModel.load()
        }

        while !service.isSuspended {
            await Task.yield()
        }

        XCTAssertTrue(viewModel.isLoading)

        service.resume(with: [Self.park])
        await task.value

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.parks, [Self.park])
    }

    private static let park = Park(
        id: TestFixtures.parkId,
        name: "Central Park",
        latitude: 50.45,
        longitude: 30.52,
        address: "Main Street",
        isActive: true,
        hasLighting: true
    )
}

@MainActor
private final class ParksServiceStub: ParksFetching {

    private var results: [Result<[Park], Error>]
    private(set) var callCount = 0

    init(
        results: [Result<[Park], Error>] = [.success([])]
    ) {
        self.results = results
    }

    func fetchParks() async throws -> [Park] {
        callCount += 1

        let result = results.count > 1
            ? results.removeFirst()
            : results[0]

        return try result.get()
    }
}

@MainActor
private final class SuspendedParksServiceStub: ParksFetching {

    private var continuation: CheckedContinuation<[Park], Error>?
    private(set) var isSuspended = false

    func fetchParks() async throws -> [Park] {
        isSuspended = true

        return try await withCheckedThrowingContinuation {
            continuation = $0
        }
    }

    func resume(
        with parks: [Park]
    ) {
        continuation?.resume(returning: parks)
        continuation = nil
    }
}

private enum MapViewModelTestError: LocalizedError {

    case secretNetworkDetails

    var errorDescription: String? {
        "secret backend network details"
    }
}
