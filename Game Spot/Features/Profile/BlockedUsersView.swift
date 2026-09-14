import SwiftUI

@MainActor
struct BlockedUsersView: View {

    @StateObject private var viewModel =
        BlockedUsersViewModel()

    var body: some View {

        Group {

            if viewModel.isLoading,
               viewModel.users.isEmpty {

                LoadingView()
                    .accessibilityIdentifier(
                        "blockedUsers.loading"
                    )

            } else if let errorMessage = viewModel.errorMessage,
                      viewModel.users.isEmpty {

                ContentStateView(
                    title: "Couldn’t Load Blocked Users",
                    message: errorMessage,
                    systemImage: "wifi.exclamationmark",
                    accessibilityIdentifier: "blockedUsers.error",
                    actionTitle: "Try Again"
                ) {
                    Task {
                        await viewModel.load()
                    }
                }

            } else if viewModel.users.isEmpty {

                ContentStateView(
                    title: "No Blocked Users",
                    message: "People you block will appear here.",
                    systemImage: "person.crop.circle.badge.checkmark",
                    accessibilityIdentifier: "blockedUsers.empty"
                )

            } else {

                List {

                    if let errorMessage = viewModel.errorMessage {

                        Section {

                            Label(
                                errorMessage,
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(.red)

                            Button("Dismiss") {
                                viewModel.clearError()
                            }
                        }
                    }

                    Section {

                        ForEach(viewModel.users) { user in

                            blockedUserRow(user)
                        }

                    } footer: {
                        Text(
                            "Unblocked users may appear again in matches and player lists."
                        )
                    }
                }
                .refreshable {
                    await viewModel.load()
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    private func blockedUserRow(
        _ user: BlockedUser
    ) -> some View {

        HStack(spacing: 12) {

            avatarView(user)

            Text(user.blockedUsername)
                .font(.headline)
                .lineLimit(1)

            Spacer()

            Button("Unblock") {
                Task {
                    await viewModel.unblock(user)
                }
            }
            .buttonStyle(.bordered)
            .disabled(
                viewModel.isUnblocking(
                    userId: user.id
                )
            )
            .accessibilityIdentifier(
                "blockedUsers.unblock.\(user.id.uuidString)"
            )
        }
        .padding(.vertical, 4)
    }

    private func avatarView(
        _ user: BlockedUser
    ) -> some View {

        AsyncImage(
            url: URL(
                string: user.blockedAvatarUrl ?? ""
            )
        ) { phase in

            switch phase {

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()

            default:
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .foregroundStyle(.white)
                    .background(Color("AccentColor"))
            }
        }
        .frame(width: 48, height: 48)
        .background(Color("AccentColor"))
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}
