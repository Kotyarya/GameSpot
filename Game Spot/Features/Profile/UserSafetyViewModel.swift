import Foundation
import Combine

@MainActor
final class UserSafetyViewModel: ObservableObject {

    @Published var selectedReason: ReportReason = .offensiveUsername
    @Published var reportDetails = ""

    @Published private(set) var isSubmittingReport = false
    @Published private(set) var isChangingBlock = false
    @Published private(set) var successMessage: String?
    @Published private(set) var errorMessage: String?

    private let service: any UserSafetyServing

    init(
        service: any UserSafetyServing = UserSafetyService.shared
    ) {
        self.service = service
    }

    func submitReport(
        userId: UUID
    ) async -> Bool {

        guard !isSubmittingReport else {
            return false
        }

        guard reportDetails.count <= 500 else {
            errorMessage =
                "Report details must be 500 characters or fewer."
            return false
        }

        isSubmittingReport = true
        successMessage = nil
        errorMessage = nil

        defer {
            isSubmittingReport = false
        }

        do {
            _ = try await service.submitReport(
                userId: userId,
                reason: selectedReason,
                details: reportDetails
            )

            reportDetails = ""

            successMessage =
                "Report submitted. Thank you for helping keep GameSpot safe."

            return true

        } catch {
            AppLogger.error(
                "UserSafetyViewModel submitReport failed",
                error: error
            )

            errorMessage =
                "Couldn’t submit the report. Please try again."

            return false
        }
    }

    func block(
        userId: UUID
    ) async -> Bool {

        guard !isChangingBlock else {
            return false
        }

        isChangingBlock = true
        successMessage = nil
        errorMessage = nil

        defer {
            isChangingBlock = false
        }

        do {
            try await service.setBlocked(
                userId: userId,
                isBlocked: true
            )

            successMessage = "User blocked."
            return true

        } catch {
            AppLogger.error(
                "UserSafetyViewModel block failed",
                error: error
            )

            errorMessage =
                "Couldn’t block this user. Please try again."

            return false
        }
    }

    func clearMessages() {
        successMessage = nil
        errorMessage = nil
    }
}
