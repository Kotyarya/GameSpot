import Foundation
import Supabase

@MainActor
protocol AccountDeleting {
    func deleteAccount() async throws
}

enum AccountDeletionError: LocalizedError {
    case notConfirmed

    var errorDescription: String? {
        "The server did not confirm account deletion."
    }
}

@MainActor
final class AccountDeletionService: AccountDeleting {

    static let shared = AccountDeletionService()

    private struct Response: Decodable {
        let deleted: Bool
    }

    private let client: SupabaseClient

    init(
        client: SupabaseClient = SupabaseService.shared.client
    ) {
        self.client = client
    }

    func deleteAccount() async throws {
        let response: Response = try await client.functions.invoke(
            "delete-account",
            options: FunctionInvokeOptions(method: .delete)
        )

        guard response.deleted else {
            throw AccountDeletionError.notConfirmed
        }
    }
}
