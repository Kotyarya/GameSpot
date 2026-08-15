import Foundation
import Supabase

@MainActor
protocol AuthServing: AnyObject {

    func signUp(
        email: String,
        password: String
    ) async throws

    func signIn(
        email: String,
        password: String
    ) async throws
}

final class AuthService: @unchecked Sendable {

    // MARK: - Shared

    static let shared = AuthService()

    // MARK: - Dependencies

    private let client =
        SupabaseService.shared.client

    // MARK: - Authentication

    func signUp(
        email: String,
        password: String
    ) async throws {

        _ = try await client.auth.signUp(
            email: email,
            password: password
        )
    }

    func signIn(
        email: String,
        password: String
    ) async throws {

        try await client.auth.signIn(
            email: email,
            password: password
        )
    }

    func signOut() async throws {

        try await client.auth.signOut()
    }

    // MARK: - Current User

    var currentUser: User? {

        client.auth.currentUser
    }

    var currentUserId: UUID? {

        client.auth.currentUser?.id
    }
}

extension AuthService: AuthServing {}
