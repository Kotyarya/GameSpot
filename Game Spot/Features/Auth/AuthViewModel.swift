import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Inputs

    @Published var email: String = ""

    @Published var password: String = ""

    // MARK: - UI State

    @Published var isLoading: Bool = false

    @Published var errorMessage: String?

    // MARK: - Validation

    var isValid: Bool {

        !email.isEmpty
        && !password.isEmpty
        && password.count >= 6
    }

    // MARK: - Authentication

    func signIn(
        session: SessionManager
    ) {

        Task {

            do {

                errorMessage = nil
                isLoading = true

                try await AuthService.shared.signIn(
                    email: email,
                    password: password
                )

                session.refreshUser()

            } catch {

                errorMessage =
                    error.localizedDescription
            }

            isLoading = false
        }
    }

    func signUp(
        session: SessionManager
    ) {

        Task {

            do {

                errorMessage = nil
                isLoading = true

                try await AuthService.shared.signUp(
                    email: email,
                    password: password
                )

                session.refreshUser()

            } catch {

                errorMessage =
                    error.localizedDescription
            }

            isLoading = false
        }
    }

    func signInWithApple(
        session: SessionManager
    ) {

        Task {

            do {

                errorMessage = nil
                isLoading = true

                try await AuthService.shared
                    .signInWithApple()

                session.refreshUser()

            } catch {

                errorMessage =
                    error.localizedDescription
            }

            isLoading = false
        }
    }
}
