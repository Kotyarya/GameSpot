import SwiftUI
import Combine
import Supabase

@MainActor
final class PasswordRecoveryViewModel: ObservableObject {

    @Published var password = ""

    @Published var confirmation = ""

    @Published private(set) var isLoading = false

    @Published private(set) var errorMessage: String?

    private let service: any PasswordRecoveryServing

    init(
        service: any PasswordRecoveryServing = AuthService.shared
    ) {
        self.service = service
    }

    var checks: [PasswordCheck] {
        PasswordPolicy.checks(for: password)
    }

    var passwordsMatch: Bool {
        PasswordPolicy.passwordsMatch(
            password,
            confirmation: confirmation
        )
    }

    var canSubmit: Bool {
        PasswordPolicy.isValid(password) && passwordsMatch
    }

    func updatePassword() async -> Bool {
        guard canSubmit, !isLoading else {
            return false
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            try await service.updatePassword(password)
            return true
        } catch {
            errorMessage = Self.userFacingMessage(for: error)
            return false
        }
    }

    private static func userFacingMessage(
        for error: Error
    ) -> String {
        guard let authError = error as? AuthError else {
            return "Couldn’t update your password. Check your connection and try again."
        }

        switch authError.errorCode {
        case .samePassword:
            return "Choose a new password that is different from your current password."
        case .weakPassword:
            return "Your new password doesn’t meet the server’s password requirements."
        case .sessionExpired,
             .sessionNotFound,
             .flowStateExpired,
             .otpExpired,
             .badCodeVerifier:
            return "This password reset session has expired. Request a new link and try again."
        default:
            return "Couldn’t update your password. Try again."
        }
    }
}

struct PasswordRecoveryView: View {

    @EnvironmentObject private var session: SessionManager

    @EnvironmentObject private var authLinks: AuthLinkCoordinator

    @StateObject private var viewModel: PasswordRecoveryViewModel

    @State private var showsPassword = false

    @State private var showsConfirmation = false

    init(
        service: any PasswordRecoveryServing = AuthService.shared
    ) {
        _viewModel = StateObject(
            wrappedValue: PasswordRecoveryViewModel(service: service)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch authLinks.state {
                case .passwordRecovery:
                    passwordForm
                case .failed(.passwordRecovery, let message):
                    invalidLinkView(message: message)
                default:
                    LoadingView()
                }
            }
            .navigationTitle("New Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelRecovery()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .accessibilityIdentifier("passwordRecovery.screen")
    }

    private var passwordForm: some View {
        Form {
            Section {
                passwordField(
                    title: "New Password",
                    text: $viewModel.password,
                    isVisible: $showsPassword,
                    identifier: "passwordRecovery.password"
                )

                passwordField(
                    title: "Confirm Password",
                    text: $viewModel.confirmation,
                    isVisible: $showsConfirmation,
                    identifier: "passwordRecovery.confirmation"
                )
            } footer: {
                Text("Use at least 8 characters, one uppercase letter, and one number.")
            }

            Section("Password Requirements") {
                ForEach(viewModel.checks) { check in
                    Label(
                        check.title,
                        systemImage: check.passed
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .foregroundStyle(check.passed ? .green : .secondary)
                }

                Label(
                    "Passwords match",
                    systemImage: viewModel.passwordsMatch
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .foregroundStyle(
                    viewModel.passwordsMatch ? .green : .secondary
                )
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(
                        errorMessage,
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("passwordRecovery.error")
                }
            }

            Section {
                Button {
                    updatePassword()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Update Password")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.canSubmit || viewModel.isLoading)
                .accessibilityIdentifier("passwordRecovery.submit")
            }
        }
    }

    private func passwordField(
        title: String,
        text: Binding<String>,
        isVisible: Binding<Bool>,
        identifier: String
    ) -> some View {
        HStack {
            Group {
                if isVisible.wrappedValue {
                    TextField(title, text: text)
                } else {
                    SecureField(title, text: text)
                }
            }
            .textContentType(.newPassword)
            .accessibilityIdentifier(identifier)

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(
                    systemName: isVisible.wrappedValue
                        ? "eye.slash.fill"
                        : "eye.fill"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func invalidLinkView(
        message: String
    ) -> some View {
        ContentUnavailableView {
            Label(
                "Reset Link Unavailable",
                systemImage: "link.badge.plus"
            )
        } description: {
            Text(message)
        } actions: {
            Button("Back to Sign In") {
                cancelRecovery()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("passwordRecovery.invalid.back")
        }
        .accessibilityIdentifier("passwordRecovery.invalid")
    }

    private func updatePassword() {
        Task {
            guard await viewModel.updatePassword() else {
                return
            }

            await session.finishPasswordRecovery()
            authLinks.reset()
        }
    }

    private func cancelRecovery() {
        Task {
            await session.cancelPasswordRecovery()
            authLinks.reset()
        }
    }
}
