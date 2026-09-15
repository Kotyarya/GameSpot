import SwiftUI

@MainActor
struct PublicProfileView: View {

    let profile: PublicProfileSummary
    let onBlocked: @MainActor () -> Void

    @StateObject private var viewModel =
        UserSafetyViewModel()

    @State private var showsReportSheet = false
    @State private var showsBlockConfirmation = false
    @State private var reportWasSubmitted = false
    @State private var presentedAlert: PublicProfileAlert?

    @Environment(\.dismiss) private var dismiss

    init(
        profile: PublicProfileSummary,
        onBlocked: @escaping @MainActor () -> Void = {}
    ) {
        self.profile = profile
        self.onBlocked = onBlocked
    }

    var body: some View {

        ScrollView {

            VStack(spacing: 28) {

                profileHeader

                statisticsSection

                safetySection
            }
            .padding()
        }
        .navigationTitle("Player")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(
            isPresented: $showsReportSheet,
            onDismiss: {
                viewModel.clearMessages()

                if reportWasSubmitted {
                    reportWasSubmitted = false
                    presentedAlert = .reportSubmitted
                }
            }
        ) {
            ReportUserSheet(
                profile: profile,
                viewModel: viewModel,
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

            Button(
                "Cancel",
                role: .cancel
            ) {}
        } message: {
            Text(
                "You won’t see this user in GameSpot social areas. You can unblock them later from your profile."
            )
        }
        .alert(
            item: $presentedAlert
        ) { alert in
            switch alert {

            case .reportSubmitted:
                Alert(
                    title: Text("Report Submitted"),
                    message: Text(
                        "Thank you for helping keep GameSpot safe. The report will be reviewed."
                    ),
                    dismissButton: .default(
                        Text("OK")
                    )
                )

            case .error(let message):
                Alert(
                    title: Text("Something Went Wrong"),
                    message: Text(message),
                    dismissButton: .default(
                        Text("OK")
                    )
                )
            }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {

        VStack(spacing: 14) {

            avatarView

            Text(profile.username)
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)

            Label(
                "\(profile.rating) rating",
                systemImage: "star.fill"
            )
            .font(.headline)
            .foregroundStyle(Color("AccentColor"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var avatarView: some View {

        AsyncImage(
            url: URL(
                string: profile.avatarUrl ?? ""
            )
        ) { phase in

            switch phase {

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()

            default:
                Image(
                    systemName: "person.fill"
                )
                .resizable()
                .scaledToFit()
                .padding(28)
                .foregroundStyle(.white)
                .background(
                    Color("AccentColor")
                )
            }
        }
        .frame(
            width: 112,
            height: 112
        )
        .background(
            Color("AccentColor")
        )
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(
                    Color("AccentColor"),
                    lineWidth: 3
                )
        }
        .accessibilityLabel(
            "\(profile.username) profile photo"
        )
    }

    // MARK: - Statistics

    private var statisticsSection: some View {

        VStack(alignment: .leading, spacing: 14) {

            Text("Player Statistics")
                .font(.headline)

            HStack(spacing: 12) {

                statisticCard(
                    title: "Rating",
                    value: "\(profile.rating)",
                    icon: "star.fill"
                )

                if let gamesPlayed = profile.gamesPlayed {
                    statisticCard(
                        title: "Games",
                        value: "\(gamesPlayed)",
                        icon: "figure.run"
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statisticCard(
        title: String,
        value: String,
        icon: String
    ) -> some View {

        VStack(spacing: 8) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(
                    Color("AccentColor")
                )

            Text(value)
                .font(.title3)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            Color.secondary.opacity(0.1)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    // MARK: - Safety

    private var safetySection: some View {

        VStack(alignment: .leading, spacing: 12) {

            Text("Safety")
                .font(.headline)

            Button {
                showsReportSheet = true
            } label: {
                Label(
                    "Report User",
                    systemImage: "exclamationmark.bubble"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier(
                "publicProfile.report"
            )

            Button(
                role: .destructive
            ) {
                showsBlockConfirmation = true
            } label: {
                HStack {

                    if viewModel.isChangingBlock {
                        ProgressView()
                    } else {
                        Image(
                            systemName: "person.crop.circle.badge.xmark"
                        )
                    }

                    Text(
                        viewModel.isChangingBlock
                        ? "Blocking…"
                        : "Block User"
                    )
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(
                viewModel.isChangingBlock
            )
            .accessibilityIdentifier(
                "publicProfile.block"
            )
        }
    }

    // MARK: - Actions

    private func blockUser() async {

        let succeeded =
            await viewModel.block(
                userId: profile.id
            )

        guard succeeded else {

            presentedAlert = .error(
                viewModel.errorMessage
                ?? "Couldn’t block this user. Please try again."
            )

            return
        }

        onBlocked()
        dismiss()
    }
}

// MARK: - Report Sheet

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
                        ForEach(
                            ReportReason.allCases
                        ) { reason in
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

                if let errorMessage =
                    viewModel.errorMessage {

                    Section {
                        Label(
                            errorMessage,
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(
                "Report \(profile.username)"
            )
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(
                viewModel.isSubmittingReport
            )
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(
                        viewModel.isSubmittingReport
                    )
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
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
                    .accessibilityIdentifier(
                        "report.submit"
                    )
                }
            }
        }
        .presentationDetents([
            .medium,
            .large
        ])
    }

    private func submitReport() async {

        let succeeded =
            await viewModel.submitReport(
                userId: profile.id
            )

        guard succeeded else {
            return
        }

        onSubmitted()
        dismiss()
    }
}

// MARK: - Alert

private enum PublicProfileAlert:
    Identifiable {

    case reportSubmitted
    case error(String)

    var id: String {
        switch self {
        case .reportSubmitted:
            return "reportSubmitted"

        case .error(let message):
            return "error-\(message)"
        }
    }
}
