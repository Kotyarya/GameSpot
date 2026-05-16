import Foundation
import Combine

@MainActor
final class ParkDetailsViewModel: ObservableObject {

    // MARK: - State

    @Published var details: ParkDetails?

    @Published var isLoading = false

    @Published var hasRated = false

    // MARK: - Services

    private let service = ParkService.shared

    // MARK: - Load

    func load(
        parkId: UUID
    ) async {

        details = nil

        isLoading = true

        defer {
            isLoading = false
        }

        do {

            details = try await service
                .fetchParkDetails(
                    parkId: parkId
                )

        } catch {

            AppLogger.error(
                "ParkDetailsViewModel load failed",
                error: error
            )
        }
    }

    // MARK: - Rating Status

    func checkIfRated(
        userId: UUID,
        parkId: UUID
    ) async {

        do {

            hasRated = try await service
                .hasUserRated(
                    userId: userId,
                    parkId: parkId
                )

        } catch {

            AppLogger.error(
                "ParkDetailsViewModel checkIfRated failed",
                error: error
            )
        }
    }

    // MARK: - Submit Rating

    func submitRating(
        userId: UUID,
        parkId: UUID,
        quality: Int,
        facilities: Int,
        activity: Int
    ) async {

        do {

            try await service
                .ratePark(
                    userId: userId,
                    parkId: parkId,
                    quality: quality,
                    facilities: facilities,
                    activity: activity
                )

            await load(
                parkId: parkId
            )

        } catch {

            AppLogger.error(
                "ParkDetailsViewModel submitRating failed",
                error: error
            )
        }
    }
}
