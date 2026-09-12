import XCTest
@testable import Game_Spot

@MainActor
final class CreateGameViewModelTests: XCTestCase {

    func testInitialState() {
        let viewModel = makeViewModel()

        XCTAssertNil(viewModel.selectedSport)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCreateGameWithoutSportReturnsNilAndSetsError() async {
        let service = CreateGameServiceStub()
        let viewModel = makeViewModel(service: service)

        let result = await viewModel.createGame(
            parkId: TestFixtures.parkId
        )

        XCTAssertNil(result)
        XCTAssertEqual(viewModel.errorMessage, "Select sport")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(service.createCallCount, 0)
    }

    func testCreateGamePublishesServiceResultAndArguments() async {
        let expectedGameId = TestFixtures.gameId
        let service = CreateGameServiceStub(result: .success(expectedGameId))
        let viewModel = makeViewModel(service: service)
        let startsAt = Date(timeIntervalSince1970: 1_800_000_000)
        viewModel.selectedSport = TestFixtures.sport()
        viewModel.startsAt = startsAt

        let result = await viewModel.createGame(
            parkId: TestFixtures.parkId
        )

        XCTAssertEqual(result, expectedGameId)
        XCTAssertEqual(service.receivedParkId, TestFixtures.parkId)
        XCTAssertEqual(service.receivedSportId, TestFixtures.sportFootballId)
        XCTAssertEqual(service.receivedStartsAt, startsAt)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCreateGameFailureStopsLoadingAndShowsError() async {
        let service = CreateGameServiceStub(result: .failure(TestError.failed))
        let viewModel = makeViewModel(service: service)
        viewModel.selectedSport = TestFixtures.sport()

        let result = await viewModel.createGame(
            parkId: TestFixtures.parkId
        )

        XCTAssertNil(result)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(
            viewModel.errorMessage,
            "Couldn’t create the game. Check your connection and try again."
        )
    }

    private func makeViewModel(
        service: (any GameCreating)? = nil
    ) -> CreateGameViewModel {

        CreateGameViewModel(
            service: service ?? CreateGameServiceStub(),
            loadingDelay: .zero
        )
    }
}

@MainActor
private final class CreateGameServiceStub: GameCreating {

    private let result: Result<UUID, Error>

    private(set) var createCallCount = 0
    private(set) var receivedParkId: UUID?
    private(set) var receivedSportId: UUID?
    private(set) var receivedStartsAt: Date?

    init(
        result: Result<UUID, Error> = .success(TestFixtures.gameId)
    ) {

        self.result = result
    }

    func createGame(
        parkId: UUID,
        sportId: UUID,
        startsAt: Date
    ) async throws -> UUID {

        createCallCount += 1
        receivedParkId = parkId
        receivedSportId = sportId
        receivedStartsAt = startsAt
        return try result.get()
    }
}

private enum TestError: LocalizedError {

    case failed

    var errorDescription: String? {
        "Test request failed"
    }
}
