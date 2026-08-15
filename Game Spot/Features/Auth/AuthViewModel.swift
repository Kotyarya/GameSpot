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

    // MARK: - Validation

    var isValid: Bool {

        !email.isEmpty
        && !password.isEmpty
        && password.count >= 6
    }

    // MARK: - Authentication

    @discardableResult
    func signIn(
        session: any SessionRefreshing
    ) -> Task<Void, Never> {

        Task { @MainActor in

            do {

                errorMessage = nil
                isLoading = true

                try await service.signIn(
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

    @discardableResult
    func signUp(
        session: any SessionRefreshing
    ) -> Task<Void, Never> {

        Task { @MainActor in

            do {

                errorMessage = nil
                isLoading = true

                try await service.signUp(
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

}
