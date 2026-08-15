import XCTest
@testable import Game_Spot

@MainActor
final class GamesViewModelTests: XCTestCase {

    func testInitialStateIsEmptyAndNotLoading() {
        let viewModel = makeViewModel()

        XCTAssertTrue(viewModel.games.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadUserGamesPublishesResultAndSubscribesOnce() async {
        let game = TestFixtures.game(
            startsAt: Date().addingTimeInterval(3_600)
        )
        let service = GamesServiceStub(userGames: .success([game]))
        let realtime = GamesRealtimeStub()
        let viewModel = makeViewModel(
            service: service,
            realtime: realtime
        )

        await viewModel.load(mode: .myGames)
        await viewModel.load(mode: .myGames)

        XCTAssertEqual(viewModel.games, [game])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(service.userGamesCallCount, 2)
        XCTAssertEqual(realtime.subscribeCallCount, 1)
    }

    func testLoadParkModeUsesRequestedPark() async {
        let game = TestFixtures.game(
            startsAt: Date().addingTimeInterval(3_600)
        )
        let service = GamesServiceStub(parkGames: .success([game]))
        let viewModel = makeViewModel(service: service)

        await viewModel.load(
            mode: .park(id: TestFixtures.parkId)
        )

        XCTAssertEqual(viewModel.games, [game])
        XCTAssertEqual(service.requestedParkIds, [TestFixtures.parkId])
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadFailureStopsLoadingAndDoesNotSubscribe() async {
        let service = GamesServiceStub(
            userGames: .failure(TestError.expected)
        )
        let realtime = GamesRealtimeStub()
        let viewModel = makeViewModel(
            service: service,
            realtime: realtime
        )

        await viewModel.load(mode: .myGames)

        XCTAssertTrue(viewModel.games.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(realtime.subscribeCallCount, 0)
    }

    func testCancelledLoadAlwaysStopsLoading() async {
        let service = GamesServiceStub(
            userGames: .failure(CancellationError())
        )
        let viewModel = makeViewModel(service: service)

        await viewModel.load(mode: .myGames)

        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadingIsVisibleUntilFetchCompletes() async {
        let service = SuspendedGamesServiceStub()
        let viewModel = makeViewModel(service: service)

        let loadTask = Task {
            await viewModel.load(mode: .myGames)
        }

        await Task.yield()
        XCTAssertTrue(viewModel.isLoading)

        service.resume(with: [])
        await loadTask.value

        XCTAssertFalse(viewModel.isLoading)
    }

    private func makeViewModel(
        service: (any GamesFetching)? = nil,
        realtime: (any GamesRealtimeSubscribing)? = nil
    ) -> GamesViewModel {
        GamesViewModel(
            service: service ?? GamesServiceStub(),
            realtime: realtime ?? GamesRealtimeStub(),
            minimumLoadingDuration: 0
        )
    }
}

private enum TestError: Error {
    case expected
}

@MainActor
private final class GamesServiceStub: GamesFetching {

    private let userGames: Result<[Game], Error>
    private let parkGames: Result<[Game], Error>

    private(set) var userGamesCallCount = 0
    private(set) var requestedParkIds: [UUID] = []

    init(
        userGames: Result<[Game], Error> = .success([]),
        parkGames: Result<[Game], Error> = .success([])
    ) {
        self.userGames = userGames
        self.parkGames = parkGames
    }

    func fetchGamesByPark(
        parkId: UUID
    ) async throws -> [Game] {
        requestedParkIds.append(parkId)
        return try parkGames.get()
    }

    func fetchUserGames() async throws -> [Game] {
        userGamesCallCount += 1
        return try userGames.get()
    }
}

@MainActor
private final class SuspendedGamesServiceStub: GamesFetching {

    private var continuation: CheckedContinuation<[Game], Error>?

    func fetchGamesByPark(
        parkId: UUID
    ) async throws -> [Game] {
        try await suspend()
    }

    func fetchUserGames() async throws -> [Game] {
        try await suspend()
    }

    func resume(with games: [Game]) {
        continuation?.resume(returning: games)
        continuation = nil
    }

    private func suspend() async throws -> [Game] {
        try await withCheckedThrowingContinuation {
            continuation = $0
        }
    }
}

@MainActor
private final class GamesRealtimeStub: GamesRealtimeSubscribing {

    private(set) var subscribeCallCount = 0
    private(set) var unsubscribeCallCount = 0

    func subscribe(
        onChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws {
        subscribeCallCount += 1
    }

    func unsubscribe() async {
        unsubscribeCallCount += 1
    }
}
