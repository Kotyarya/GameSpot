import SwiftUI
import Combine

@MainActor
final class PasswordResetRequestViewModel: ObservableObject {

    @Published var email: String

    @Published private(set) var isLoading = false

    @Published private(set) var didSendRequest = false

    @Published private(set) var errorMessage: String?

    private let service: any PasswordRecoveryServing

    init(
        email: String = "",
        service: any PasswordRecoveryServing = AuthService.shared
    ) {

        self.email = email
        self.service = service
    }

    var canSubmit: Bool {
        let parts = normalizedEmail.split(separator: "@")
        return parts.count == 2 && parts[1].contains(".")
    }

    @discardableResult
    func requestReset() -> Task<Void, Never> {

        Task { @MainActor in
            guard canSubmit, !isLoading else {
                return
            }

            isLoading = true
            errorMessage = nil

            do {
                try await service.requestPasswordReset(
                    email: normalizedEmail
                )

                didSendRequest = true

            } catch {
                errorMessage = "Couldn’t send a reset email. Check your connection and try again."
            }

            isLoading = false
        }
    }

    private var normalizedEmail: String {
        email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

struct PasswordResetRequestView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: PasswordResetRequestViewModel

    init(
        initialEmail: String = "",
        service: any PasswordRecoveryServing = AuthService.shared
    ) {

        _viewModel = StateObject(
            wrappedValue: PasswordResetRequestViewModel(
                email: initialEmail,
                service: service
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.didSendRequest {
                    sentView
                } else {
                    requestForm
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isLoading)
        .accessibilityIdentifier("passwordReset.request.screen")
    }

    private var requestForm: some View {
        Form {
            Section {
                TextField(
                    "Email address",
                    text: $viewModel.email
                )
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .textContentType(.emailAddress)
                .accessibilityIdentifier("passwordReset.request.email")
            } header: {
                Text("Account Email")
            } footer: {
                Text("We’ll send a reset link if an account exists. Open the link on this device.")
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(
                        errorMessage,
                        systemImage: "exclamationmark.circle.fill"
                    )
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("passwordReset.request.error")
                }
            }

            Section {
                Button {
                    viewModel.requestReset()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Send Reset Link")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.canSubmit || viewModel.isLoading)
                .accessibilityIdentifier("passwordReset.request.submit")
            }
        }
    }

    private var sentView: some View {
        ContentUnavailableView {
            Label(
                "Check Your Email",
                systemImage: "envelope.badge"
            )
        } description: {
            Text(
                "If an account exists for that address, a password reset link has been sent. Open it on this device."
            )
        } actions: {
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("passwordReset.request.done")
        }
        .accessibilityIdentifier("passwordReset.request.sent")
    }
}
