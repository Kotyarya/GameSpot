import Foundation
import Combine

@MainActor
final class MapViewModel: ObservableObject {

    // MARK: - State

    @Published var parks: [Park] = []

    @Published var selectedPark: Park?

    @Published var isLoading = false

    // MARK: - Services

    private let service = ParkService.shared

    // MARK: - Load

    func load() async {

        isLoading = true

        defer {
            isLoading = false
        }

        do {

            parks = try await service
                .fetchParks()

        } catch {

            AppLogger.error(
                "MapViewModel load failed",
                error: error
            )
        }
    }
}
