import Foundation
import Supabase

enum AuthSignUpResult: Equatable {

    case signedIn
    case confirmationRequired(email: String)
}

@MainActor
protocol AuthServing: AnyObject {

    func signUp(
        email: String,
        password: String
    ) async throws -> AuthSignUpResult

    func signIn(
        email: String,
        password: String
    ) async throws

    func resendSignUpConfirmation(
        email: String
    ) async throws
}

@MainActor
protocol PasswordRecoveryServing: AnyObject {

    func requestPasswordReset(
        email: String
    ) async throws

    func updatePassword(
        _ password: String
    ) async throws
}

@MainActor
protocol SessionAuthServing: AnyObject {

    var currentUser: User? { get }

    func signOut() async throws
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
    ) async throws -> AuthSignUpResult {

        let response = try await client.auth.signUp(
            email: email,
            password: password,
            redirectTo: AuthRedirect.emailConfirmation
        )

        if response.session != nil {
            return .signedIn
        }

        return .confirmationRequired(email: email)
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

    func resendSignUpConfirmation(
        email: String
    ) async throws {

        try await client.auth.resend(
            email: email,
            type: .signup,
            emailRedirectTo: AuthRedirect.emailConfirmation
        )
    }

    func requestPasswordReset(
        email: String
    ) async throws {

        try await client.auth.resetPasswordForEmail(
            email,
            redirectTo: AuthRedirect.passwordRecovery
        )
    }

    func updatePassword(
        _ password: String
    ) async throws {

        try await client.auth.update(
            user: UserAttributes(password: password)
        )
    }

    func exchangeAuthSession(
        from url: URL
    ) async throws {

        _ = try await client.auth.session(from: url)
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
extension AuthService: PasswordRecoveryServing {}
extension AuthService: SessionAuthServing {}
extension AuthService: AuthLinkExchanging {}
