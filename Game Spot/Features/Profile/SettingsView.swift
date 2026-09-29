import SwiftUI

@MainActor
struct SettingsView: View {

    @StateObject private var accountDeletionViewModel:
        AccountDeletionViewModel

    init(
        accountDeletionViewModel: AccountDeletionViewModel =
            AccountDeletionViewModel()
    ) {
        _accountDeletionViewModel = StateObject(
            wrappedValue: accountDeletionViewModel
        )
    }

    @EnvironmentObject private var session:
        SessionManager

    @State private var showsSignOutConfirmation = false
    @State private var showsDeleteConfirmation = false
    @State private var accountDeletionAlert: SettingsAlert?

    private var appVersion: String {

        let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "1.0"

        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String ?? "1"

        return "Version \(version) (\(build))"
    }

    var body: some View {

        List {

            Section("Privacy & Safety") {
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label(
                        "Privacy Policy",
                        systemImage: "hand.raised.fill"
                    )
                }
                .accessibilityIdentifier(
                    "settings.privacyPolicy"
                )

                NavigationLink {
                    BlockedUsersView()
                } label: {
                    Label(
                        "Blocked Users",
                        systemImage:
                            "person.crop.circle.badge.xmark"
                    )
                }
                .accessibilityIdentifier(
                    "settings.blockedUsers"
                )
            }

            Section("Support") {
                Link(
                    destination: URL(
                        string:
                            "mailto:gamespot.support@icloud.com"
                    )!
                ) {
                    Label(
                        "Contact Support",
                        systemImage: "envelope.fill"
                    )
                }
                .accessibilityIdentifier("settings.support")

                LabeledContent(
                    "About GameSpot",
                    value: appVersion
                )
                .accessibilityIdentifier("settings.about")
            }

            Section {
                Button {
                    showsSignOutConfirmation = true
                } label: {
                    Label(
                        "Sign Out",
                        systemImage:
                            "rectangle.portrait.and.arrow.right"
                    )
                }
                .accessibilityIdentifier("settings.signOut")

                Button(role: .destructive) {
                    showsDeleteConfirmation = true
                } label: {
                    HStack {
                        Label(
                            accountDeletionViewModel.isDeleting
                            ? "Deleting Account…"
                            : "Delete Account",
                            systemImage: "trash"
                        )
                        .foregroundStyle(Color.red)

                        if accountDeletionViewModel.isDeleting {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
                .disabled(
                    accountDeletionViewModel.isDeleting
                )
                .accessibilityIdentifier(
                    "settings.deleteAccount"
                )
            } header: {
                Text("Account")
            } footer: {
                Text(
                    "Deleting your account permanently removes your profile and related GameSpot data."
                )
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.screen")
        .confirmationDialog(
            "Sign Out?",
            isPresented: $showsSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await session.signOut()
                }
            }
            .accessibilityIdentifier(
                "settings.signOut.confirm"
            )

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "You can sign in again with the same account."
            )
        }
        .confirmationDialog(
            "Delete Account?",
            isPresented: $showsDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Continue", role: .destructive) {
                accountDeletionAlert = .finalConfirmation
            }
            .accessibilityIdentifier(
                "settings.deleteAccount.continue"
            )

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This permanently removes your profile, avatar, match participation, MVP votes, and park reviews."
            )
        }
        .alert(item: $accountDeletionAlert) { alert in
            switch alert {
            case .finalConfirmation:
                Alert(
                    title: Text(
                        "Permanently Delete Account?"
                    ),
                    message: Text(
                        "This action cannot be undone. You will be signed out and will not be able to sign in to this account again."
                    ),
                    primaryButton: .destructive(
                        Text("Delete Forever")
                    ) {
                        Task {
                            await deleteAccount()
                        }
                    },
                    secondaryButton: .cancel()
                )

            case .error(let message):
                Alert(
                    title: Text(
                        "Couldn’t Delete Account"
                    ),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func deleteAccount() async {

        guard await accountDeletionViewModel
            .deleteAccount() else {

            accountDeletionAlert = .error(
                accountDeletionViewModel.errorMessage
                ?? "Please try again."
            )
            return
        }

        await session.completeAccountDeletion()
    }
}

private enum SettingsAlert: Identifiable {
    case finalConfirmation
    case error(String)

    var id: String {
        switch self {
        case .finalConfirmation:
            "finalConfirmation"
        case .error(let message):
            "error-\(message)"
        }
    }
}
