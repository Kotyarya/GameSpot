import Foundation
import Combine

@MainActor
final class MapViewModel: ObservableObject {

    // MARK: - State

    @Published var parks: [Park] = []

    @Published var selectedPark: Park?

    @Published var isLoading = false

    @Published private(set) var errorMessage: String?

    // MARK: - Services

    private let service: any ParksFetching

    // MARK: - Init

    init(
        service: any ParksFetching = ParkService.shared
    ) {
        self.service = service
    }

    // MARK: - Load

    func load() async {

        guard !isLoading else {
            return
        }

        isLoading = true

        errorMessage = nil

        defer {
            isLoading = false
        }

        do {

            parks = try await service
                .fetchParks()

        } catch {

            if error is CancellationError {
                return
            }

            errorMessage =
                "Couldn’t load parks. Check your connection and try again."

            AppLogger.error(
                "MapViewModel load failed",
                error: error
            )
        }
    }
}
