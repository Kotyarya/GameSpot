import Foundation
import Combine

@MainActor
final class AccountDeletionViewModel: ObservableObject {

    @Published private(set) var isDeleting = false
    @Published private(set) var errorMessage: String?

    private let service: any AccountDeleting

    init(
        service: any AccountDeleting = AccountDeletionService.shared
    ) {
        self.service = service
    }

    func deleteAccount() async -> Bool {
        guard !isDeleting else {
            return false
        }

        isDeleting = true
        errorMessage = nil

        defer {
            isDeleting = false
        }

        do {
            try await service.deleteAccount()
            return true
        } catch {
            AppLogger.error(
                "Account deletion failed",
                error: error
            )

            errorMessage =
                "We couldn’t delete your account. Please check your connection and try again."

            return false
        }
    }
}
