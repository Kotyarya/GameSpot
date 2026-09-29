import SwiftUI

@MainActor
struct PublicProfileView: View {

    let profile: PublicProfileSummary
    let onBlocked: @MainActor () -> Void

    @StateObject private var profileViewModel: PublicProfileViewModel

    @StateObject private var safetyViewModel: UserSafetyViewModel

    @State private var showsReportSheet = false
    @State private var showsBlockConfirmation = false
    @State private var reportWasSubmitted = false
    @State private var presentedAlert: PublicProfileAlert?

    @Environment(\.dismiss) private var dismiss

    init(
        profile: PublicProfileSummary,
        onBlocked: @escaping @MainActor () -> Void = {},
        profileViewModel: PublicProfileViewModel = PublicProfileViewModel(),
        safetyViewModel: UserSafetyViewModel = UserSafetyViewModel()
    ) {
        self.profile = profile
        self.onBlocked = onBlocked
        _profileViewModel = StateObject(wrappedValue: profileViewModel)
        _safetyViewModel = StateObject(wrappedValue: safetyViewModel)
    }

    var body: some View {

        Group {
            if profileViewModel.isLoading,
               profileViewModel.profile == nil {

                NativeLoadingView(
                    title: "Loading Player"
                )
                    .accessibilityIdentifier(
                        "publicProfile.loading"
                    )

            } else if let errorMessage =
                        profileViewModel.errorMessage,
                      profileViewModel.profile == nil {

                ContentStateView(
                    title: "Couldn’t Load Player",
                    message: errorMessage,
                    systemImage:
                        "person.crop.circle.badge.exclamationmark",
                    accessibilityIdentifier:
                        "publicProfile.error",
                    actionTitle: "Try Again"
                ) {
                    Task {
                        await profileViewModel.load(
                            userId: profile.id
                        )
                    }
                }

            } else if let loadedProfile =
                        profileViewModel.profile {

                profileContent(loadedProfile)
            }
        }
        .navigationTitle(profile.username)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await profileViewModel.load(
                userId: profile.id
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showsReportSheet = true
                    } label: {
                        Label(
                            "Report User",
                            systemImage:
                                "exclamationmark.bubble"
                        )
                    }
                    .accessibilityIdentifier(
                        "publicProfile.report"
                    )

                    Button(role: .destructive) {
                        showsBlockConfirmation = true
                    } label: {
                        Label(
                            safetyViewModel.isChangingBlock
                            ? "Blocking…"
                            : "Block User",
                            systemImage:
                                "person.crop.circle.badge.xmark"
                        )
                    }
                    .disabled(
                        safetyViewModel.isChangingBlock
                    )
                    .accessibilityIdentifier(
                        "publicProfile.block"
                    )
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Player Actions")
                .accessibilityIdentifier(
                    "publicProfile.actions"
                )
            }
        }
        .sheet(
            isPresented: $showsReportSheet,
            onDismiss: {
                safetyViewModel.clearMessages()

                if reportWasSubmitted {
                    reportWasSubmitted = false
                    presentedAlert = .reportSubmitted
                }
            }
        ) {
            ReportUserSheet(
                profile: profile,
                viewModel: safetyViewModel,
                onSubmitted: {
                    reportWasSubmitted = true
                }
            )
        }
        .confirmationDialog(
            "Block \(profile.username)?",
            isPresented: $showsBlockConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Block User",
                role: .destructive
            ) {
                Task {
                    await blockUser()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Their roster position stays visible, but their profile and other social content will be hidden. You can unblock them later in Settings."
            )
        }
        .alert(item: $presentedAlert) { alert in
            switch alert {
            case .reportSubmitted:
                Alert(
                    title: Text("Report Submitted"),
                    message: Text(
                        "Thank you for helping keep GameSpot safe. The report will be reviewed."
                    ),
                    dismissButton: .default(Text("OK"))
                )

            case .error(let message):
                Alert(
                    title: Text("Something Went Wrong"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func profileContent(
        _ loadedProfile: Profile
    ) -> some View {

        let username =
            loadedProfile.username ?? profile.username

        let rank = RankHelper.getRank(
            rating: loadedProfile.rating
        )

        return ScrollView {

            VStack(spacing: 32) {

                ProfileHeroView(
                    username: username,
                    rating: loadedProfile.rating,
                    favoriteSportIcon:
                        loadedProfile.favoriteSport?
                            .type?
                            .iconName
                        ?? "trophy.fill"
                ) {
                    ProfileAvatarView(
                        username: username,
                        avatarURL: loadedProfile.avatarUrl,
                        rank: rank
                    )
                }

                VStack(spacing: 32) {

                    ProfileSummaryCard(
                        rating: loadedProfile.rating,
                        gamesPlayed:
                            loadedProfile.gamesPlayed,
                        mvpCount: loadedProfile.mvpCount,
                        perfPoints:
                            loadedProfile.perfPoints
                    )

                    if profileViewModel.stats.isEmpty {
                        ContentStateView(
                            title: "No Sport Activity Yet",
                            message:
                                "This player hasn’t built sport stats yet.",
                            systemImage: "figure.run",
                            accessibilityIdentifier:
                                "publicProfile.stats.empty"
                        )
                        .frame(minHeight: 220)
                        .glassEffect(
                            .regular.tint(.clear),
                            in: RoundedRectangle(
                                cornerRadius: 24,
                                style: .continuous
                            )
                        )

                    } else {
                        ProfileSportStatsSection(
                            stats: profileViewModel.stats
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .ignoresSafeArea()
        .contentMargins(.bottom, 80)
        .accessibilityIdentifier("publicProfile.content")
    }

    private func blockUser() async {

        let succeeded = await safetyViewModel.block(
            userId: profile.id
        )

        guard succeeded else {
            presentedAlert = .error(
                safetyViewModel.errorMessage
                ?? "Couldn’t block this user. Please try again."
            )
            return
        }

        onBlocked()
        dismiss()
    }
}

@MainActor
private struct ReportUserSheet: View {

    let profile: PublicProfileSummary
    let onSubmitted: @MainActor () -> Void

    @ObservedObject var viewModel:
        UserSafetyViewModel

    @Environment(\.dismiss) private var dismiss

    init(
        profile: PublicProfileSummary,
        viewModel: UserSafetyViewModel,
        onSubmitted: @escaping @MainActor () -> Void
    ) {
        self.profile = profile
        self.viewModel = viewModel
        self.onSubmitted = onSubmitted
    }

    var body: some View {

        NavigationStack {

            Form {

                Section {
                    Picker(
                        "Reason",
                        selection: $viewModel.selectedReason
                    ) {
                        ForEach(ReportReason.allCases) { reason in
                            Text(reason.title)
                                .tag(reason)
                        }
                    }
                } header: {
                    Text("Reason")
                } footer: {
                    Text(
                        "Choose the reason that best describes the problem."
                    )
                }

                Section {
                    TextEditor(
                        text: $viewModel.reportDetails
                    )
                    .frame(minHeight: 120)
                    .accessibilityIdentifier(
                        "report.details"
                    )

                    Text(
                        "\(viewModel.reportDetails.count)/500"
                    )
                    .font(.caption)
                    .foregroundStyle(
                        viewModel.reportDetails.count > 500
                        ? .red
                        : .secondary
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .trailing
                    )
                } header: {
                    Text("Additional Details")
                } footer: {
                    Text(
                        "Do not include passwords or other sensitive information."
                    )
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label(
                            errorMessage,
                            systemImage:
                                "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Report \(profile.username)")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(
                viewModel.isSubmittingReport
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isSubmittingReport)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            await submitReport()
                        }
                    } label: {
                        if viewModel.isSubmittingReport {
                            ProgressView()
                        } else {
                            Text("Submit")
                        }
                    }
                    .disabled(
                        viewModel.isSubmittingReport
                        || viewModel.reportDetails.count > 500
                    )
                    .accessibilityIdentifier("report.submit")
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func submitReport() async {

        let succeeded = await viewModel.submitReport(
            userId: profile.id
        )

        guard succeeded else {
            return
        }

        onSubmitted()
        dismiss()
    }
}

private enum PublicProfileAlert: Identifiable {
    case reportSubmitted
    case error(String)

    var id: String {
        switch self {
        case .reportSubmitted:
            "reportSubmitted"
        case .error(let message):
            "error-\(message)"
        }
    }
}
