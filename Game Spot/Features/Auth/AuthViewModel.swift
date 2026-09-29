import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {

    private let service: any AuthServing

    // MARK: - Init

    init(
        service: any AuthServing = AuthService.shared
    ) {

        self.service = service
    }

    // MARK: - Inputs

    @Published var email: String = ""

    @Published var password: String = ""

    // MARK: - UI State

    @Published var isLoading: Bool = false

    @Published var errorMessage: String?

    @Published private(set) var statusMessage: String?

    @Published private(set) var pendingConfirmationEmail: String?

    // MARK: - Validation

    var isValid: Bool {

        !normalizedEmail.isEmpty
        && !password.isEmpty
        && password.count >= 6
    }

    // MARK: - Authentication

    @discardableResult
    func signIn(
        session: any SessionRefreshing
    ) -> Task<Void, Never> {

        Task { @MainActor in

            guard !isLoading else {
                return
            }

            do {

                resetFeedback()
                isLoading = true

                try await service.signIn(
                    email: normalizedEmail,
                    password: password
                )

                session.refreshUser()

            } catch {

                errorMessage = "Couldn’t sign in. Check your details and connection, then try again."
            }

            isLoading = false
        }
    }

    @discardableResult
    func signUp(
        session: any SessionRefreshing
    ) -> Task<Void, Never> {

        Task { @MainActor in

            guard !isLoading else {
                return
            }

            do {

                resetFeedback()
                pendingConfirmationEmail = nil
                isLoading = true

                let result = try await service.signUp(
                    email: normalizedEmail,
                    password: password
                )

                switch result {
                case .signedIn:
                    session.refreshUser()
                case .confirmationRequired(let email):
                    pendingConfirmationEmail = email
                    statusMessage = nil
                }

            } catch {

                errorMessage = "Couldn’t create your account. Check your connection and try again."
            }

            isLoading = false
        }
    }

    @discardableResult
    func resendSignUpConfirmation() -> Task<Void, Never> {

        Task { @MainActor in

            guard let pendingConfirmationEmail else {
                return
            }

            errorMessage = nil
            statusMessage = nil
            isLoading = true

            do {
                try await service.resendSignUpConfirmation(
                    email: pendingConfirmationEmail
                )

                statusMessage = "Confirmation email sent. Open the link on this device."

            } catch {
                errorMessage = "Couldn’t resend the confirmation email. Please try again."
            }

            isLoading = false
        }
    }

    func returnToSignIn() {
        pendingConfirmationEmail = nil
        resetFeedback()
        password = ""
    }

    func resetFeedback() {
        statusMessage = nil
        errorMessage = nil
    }

    var normalizedEmail: String {
        email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

}
