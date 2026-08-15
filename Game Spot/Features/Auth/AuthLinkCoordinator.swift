import Foundation
import Combine

@MainActor
protocol AuthLinkExchanging: AnyObject {

    func exchangeAuthSession(
        from url: URL
    ) async throws
}

enum AuthLinkState: Equatable {

    case idle
    case processing(AuthLinkRoute)
    case passwordRecovery
    case emailConfirmed
    case failed(AuthLinkRoute, message: String)
}

@MainActor
final class AuthLinkCoordinator: ObservableObject {

    @Published private(set) var state: AuthLinkState

    private let service: any AuthLinkExchanging

    init(
        service: any AuthLinkExchanging = AuthService.shared,
        initialState: AuthLinkState = .idle
    ) {

        self.service = service

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(
            "--ui-test-password-recovery-ready"
        ) {
            state = .passwordRecovery
        } else if ProcessInfo.processInfo.arguments.contains(
            "--ui-test-password-recovery-expired"
        ) {
            state = .failed(
                .passwordRecovery,
                message: Self.passwordRecoveryFailureMessage
            )
        } else {
            state = initialState
        }
        #else
        state = initialState
        #endif
    }

    @discardableResult
    func handle(
        _ url: URL
    ) async -> AuthLinkRoute? {

        guard let route = AuthRedirect.route(for: url) else {
            return nil
        }

        state = .processing(route)

        do {
            try await service.exchangeAuthSession(from: url)

            switch route {
            case .emailConfirmation:
                state = .emailConfirmed
            case .passwordRecovery:
                state = .passwordRecovery
            }

        } catch {
            state = .failed(
                route,
                message: failureMessage(for: route)
            )
        }

        return route
    }

    func reset() {
        state = .idle
    }

    var isProcessing: Bool {
        if case .processing = state {
            return true
        }
        return false
    }

    var showsPasswordRecovery: Bool {
        switch state {
        case .passwordRecovery, .failed(.passwordRecovery, _):
            return true
        default:
            return false
        }
    }

    var emailConfirmationError: String? {
        if case .failed(.emailConfirmation, let message) = state {
            return message
        }
        return nil
    }

    private func failureMessage(
        for route: AuthLinkRoute
    ) -> String {

        switch route {
        case .emailConfirmation:
            return "This confirmation link is invalid or expired. Please sign up again."
        case .passwordRecovery:
            return Self.passwordRecoveryFailureMessage
        }
    }

    private static let passwordRecoveryFailureMessage =
        "This password reset link is invalid, expired, or already used. Request a new link."
}
