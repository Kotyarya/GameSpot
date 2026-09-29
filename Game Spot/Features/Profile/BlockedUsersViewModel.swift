import Foundation
import Combine

@MainActor
final class BlockedUsersViewModel: ObservableObject {

    @Published private(set) var users: [BlockedUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var unblockingUserIds: Set<UUID> = []
    @Published private(set) var errorMessage: String?

    private let service: any UserSafetyServing

    init(
        service: any UserSafetyServing = UserSafetyService.shared
    ) {
        self.service = service
    }

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
            users = try await service.fetchBlockedUsers()

        } catch {
            AppLogger.error(
                "BlockedUsersViewModel load failed",
                error: error
            )

            errorMessage =
                "Couldn’t load blocked users. Check your connection and try again."
        }
    }

    func unblock(
        _ user: BlockedUser
    ) async {

        guard !unblockingUserIds.contains(user.id) else {
            return
        }

        unblockingUserIds.insert(user.id)
        errorMessage = nil

        defer {
            unblockingUserIds.remove(user.id)
        }

        do {
            try await service.setBlocked(
                userId: user.id,
                isBlocked: false
            )

            users.removeAll {
                $0.id == user.id
            }

        } catch {
            AppLogger.error(
                "BlockedUsersViewModel unblock failed",
                error: error
            )

            errorMessage =
                "Couldn’t unblock this user. Please try again."
        }
    }

    func isUnblocking(
        userId: UUID
    ) -> Bool {
        unblockingUserIds.contains(userId)
    }

    func clearError() {
        errorMessage = nil
    }
}
