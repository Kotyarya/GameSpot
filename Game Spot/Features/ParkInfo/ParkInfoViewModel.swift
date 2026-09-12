import Foundation
import Combine

@MainActor
final class ParkDetailsViewModel: ObservableObject {

    // MARK: - State

    @Published var details: ParkDetails?

    @Published var isLoading = false

    @Published var hasRated = false

    @Published private(set) var errorMessage: String?

    @Published private(set) var ratingErrorMessage: String?

    @Published private(set) var isSubmittingRating = false

    // MARK: - Services

    private let service: any ParkDetailsServing

    private var requestedParkId: UUID?

    private var ratingMutationVersion = 0

    // MARK: - Init

    init(
        service: any ParkDetailsServing = ParkService.shared
    ) {
        self.service = service
    }

    // MARK: - Load

    func load(
        parkId: UUID
    ) async {

        if isLoading,
           requestedParkId == parkId {
            return
        }

        if details?.park.id != parkId {
            details = nil
            hasRated = false
            ratingErrorMessage = nil
            ratingMutationVersion += 1
        }

        requestedParkId = parkId

        isLoading = true

        errorMessage = nil

        defer {
            if requestedParkId == parkId {
                isLoading = false
            }
        }

        do {

            let loadedDetails = try await service
                .fetchParkDetails(
                    parkId: parkId
                )

            guard requestedParkId == parkId else {
                return
            }

            details = loadedDetails

        } catch {

            guard requestedParkId == parkId else {
                return
            }

            if error is CancellationError {
                return
            }

            errorMessage =
                "Couldn’t load this park. Check your connection and try again."

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

        let version = ratingMutationVersion

        do {

            let result = try await service
                .hasUserRated(
                    userId: userId,
                    parkId: parkId
                )

            guard requestedParkId == parkId,
                  ratingMutationVersion == version else {
                return
            }

            hasRated = result

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
    ) async -> Bool {

        guard !isSubmittingRating else {
            return false
        }

        isSubmittingRating = true

        ratingErrorMessage = nil

        ratingMutationVersion += 1

        defer {
            isSubmittingRating = false
        }

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

            hasRated = true

            return true

        } catch {

            ratingErrorMessage =
                "Couldn’t submit your rating. Check your connection and try again."

            AppLogger.error(
                "ParkDetailsViewModel submitRating failed",
                error: error
            )

            return false
        }
    }
}
