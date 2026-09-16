import SwiftUI
import PhotosUI
internal import Auth

@MainActor
struct ProfileView: View {

    // MARK: - View Model

    @StateObject private var viewModel: ProfileViewModel

    init(
        viewModel: ProfileViewModel = ProfileViewModel()
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @State private var selectedAvatarItem: PhotosPickerItem?
    @State private var showsRemoveAvatarConfirmation = false
    @State private var isEditingProfile = false
    @State private var avatarJiggles = false

    // MARK: - Environment

    @EnvironmentObject var session:
        SessionManager

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Overall Rank

    private var rank: Rank {

        let rating =
            viewModel.profile?.rating ?? 0

        return RankHelper.getRank(
            rating: rating
        )
    }

    // MARK: - Body

    var body: some View {

        ZStack {

            contentView
        }
        .task {

            guard viewModel.profile == nil,
                  let userId = session.user?.id else {
                return
            }

            await viewModel.load(
                userId: userId
            )
        }
        .onChange(of: selectedAvatarItem) { _, item in
            Task {
                await replaceAvatar(from: item)
            }
        }
        .onChange(of: isEditingProfile) { _, isEditing in
            avatarJiggles = isEditing && !reduceMotion
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
                .accessibilityIdentifier("profile.settings")
            }

            if viewModel.profile != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        isEditingProfile ? "Done" : "Edit"
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditingProfile.toggle()
                        }
                    }
                    .accessibilityIdentifier("profile.edit")
                }
            }
        }
        .confirmationDialog(
            "Remove Profile Photo?",
            isPresented: $showsRemoveAvatarConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove Photo", role: .destructive) {
                Task {
                    await removeAvatar()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your profile will use the default avatar.")
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {

        if viewModel.isLoading {

            NativeLoadingView(
                title: "Loading Profile"
            )
                .transition(
                    .opacity.combined(
                        with: .scale(scale: 0.98)
                    )
                )

        } else if let error =
                    viewModel.errorMessage {

            ContentStateView(
                title: "Couldn’t Load Profile",
                message: error,
                systemImage: "wifi.exclamationmark",
                accessibilityIdentifier: "profile.error",
                actionTitle: "Try Again",
                action: retryProfileLoad
            )

        } else if viewModel.profile == nil {

            ContentStateView(
                title: "Profile Unavailable",
                message: "Your profile isn’t available right now. Try loading it again.",
                systemImage: "person.crop.circle.badge.exclamationmark",
                accessibilityIdentifier: "profile.empty",
                actionTitle: "Try Again",
                action: retryProfileLoad
            )

        } else {

            profileContent
        }
    }

    // MARK: - Profile Content

    private var profileContent: some View {

        ScrollView {

            VStack {

                headerSection

                contentSections
            }
        }
        .ignoresSafeArea()
        .contentMargins(.bottom, 120)
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {

        if let profile = viewModel.profile {
            ProfileHeroView(
                username: profile.username ?? "Nickname",
                rating: profile.rating,
                favoriteSportIcon:
                    profile.favoriteSport?
                        .type?
                        .iconName
                    ?? "trophy.fill"
            ) {
                editableAvatar(profile)
            }
        }
    }

    @ViewBuilder
    private func editableAvatar(
        _ profile: Profile
    ) -> some View {

        let avatar = ProfileAvatarView(
            username: profile.username ?? "Nickname",
            avatarURL: profile.avatarUrl,
            rank: rank
        )

        if isEditingProfile {
            PhotosPicker(
                selection: $selectedAvatarItem,
                matching: .images
            ) {
                avatar
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: "pencil")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(9)
                            .background(
                                Color("AccentColor"),
                                in: Circle()
                            )
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            }
                    }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isUpdatingAvatar)
            .rotationEffect(
                .degrees(
                    reduceMotion
                    ? 0
                    : avatarJiggles ? 1.5 : -1.5
                )
            )
            .animation(
                reduceMotion
                ? .default
                : .easeInOut(duration: 0.12)
                    .repeatForever(autoreverses: true),
                value: avatarJiggles
            )
            .accessibilityIdentifier("profile.avatar.choose")

        } else {
            avatar
        }
    }

    // MARK: - Sections

    private var contentSections: some View {

        VStack(spacing: 32) {

            overallProfileSection

            if viewModel.recentMatches.isEmpty,
               viewModel.stats.isEmpty {

                emptyActivitySection

            } else {

                recentMatchesSection

                sportStatsSection
            }

            if isEditingProfile {
                avatarEditingSection
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
    }

    private var emptyActivitySection: some View {

        ContentStateView(
            title: "No Activity Yet",
            message: "Join your first game to start building match history and sport stats.",
            systemImage: "figure.run",
            accessibilityIdentifier: "profile.activity.empty"
        )
        .frame(minHeight: 220)
        .glassEffect(
            .regular.tint(.clear),
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }

    private func retryProfileLoad() {

        guard let userId = session.user?.id else {
            return
        }

        Task {
            await viewModel.load(userId: userId)
        }
    }

    // MARK: - Overall Profile

    private var overallProfileSection: some View {

        ProfileSummaryCard(
            rating: viewModel.profile?.rating ?? 0,
            gamesPlayed:
                viewModel.profile?.gamesPlayed ?? 0,
            mvpCount: viewModel.profile?.mvpCount ?? 0,
            perfPoints:
                viewModel.profile?.perfPoints ?? 0
        )
    }

    // MARK: - Avatar Editing

    private var avatarEditingSection: some View {

        VStack(spacing: 12) {

            if viewModel.profile?.avatarUrl != nil {
                Button(
                    "Remove Profile Photo",
                    systemImage: "trash",
                    role: .destructive
                ) {
                    showsRemoveAvatarConfirmation = true
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isUpdatingAvatar)
                .accessibilityIdentifier("profile.avatar.remove")
            }

            if viewModel.isUpdatingAvatar {

                HStack(spacing: 10) {
                    ProgressView()
                    Text("Updating photo…")
                }
                .font(.subheadline)
                .accessibilityIdentifier("profile.avatar.updating")
            }

            if let error = viewModel.avatarErrorMessage {

                Label(
                    error,
                    systemImage: "exclamationmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.red)
                .accessibilityIdentifier("profile.avatar.error")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func replaceAvatar(
        from item: PhotosPickerItem?
    ) async {

        defer {
            selectedAvatarItem = nil
        }

        guard let item,
              let userId = session.user?.id else {
            return
        }

        do {
            guard let data = try await item.loadTransferable(
                type: Data.self
            ),
                  let image = UIImage(data: data) else {
                viewModel.showAvatarSelectionError()
                return
            }

            await viewModel.replaceAvatar(
                with: image,
                userId: userId
            )

        } catch {
            viewModel.showAvatarSelectionError()
        }
    }

    private func removeAvatar() async {

        guard let userId = session.user?.id else {
            return
        }

        await viewModel.removeAvatar(userId: userId)
    }

    // MARK: - Recent Matches

    @ViewBuilder
    private var recentMatchesSection: some View {

        if !viewModel.recentMatches.isEmpty {

            VStack(alignment: .leading) {

                Text("Recent Matches")
                    .font(.largeTitle)
                    .bold()

                VStack(spacing: 14) {

                    ForEach(
                        viewModel.recentMatches
                    ) { match in

                        RecentMatchCard(
                            match: match
                        )
                    }
                }
            }
        }
    }

    // MARK: - Sport Stats

    private var sportStatsSection: some View {
        ProfileSportStatsSection(
            stats: viewModel.stats
        )
    }
}

// MARK: - Pattern Background

struct PatternBackground: View {

    let symbol: String
    let color: Color
    let opacity: Double

    let columns = Array(
        repeating: GridItem(.flexible()),
        count: 6
    )

    var body: some View {

        LazyVGrid(
            columns: columns,
            spacing: 20
        ) {

            ForEach(
                0..<80,
                id: \.self
            ) { index in

                let row = index / 6
                let col = index % 6

                if (row + col) % 2 == 0 {

                    Image(systemName: symbol)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: 44,
                            height: 44
                        )
                        .foregroundStyle(color)
                        .opacity(opacity)

                } else {

                    Color.clear
                        .frame(
                            width: 44,
                            height: 44
                        )
                }
            }
        }
    }
}

// MARK: - Recent Match Card

struct RecentMatchCard: View {

    let match: RecentMatch

    // MARK: - Helpers

    private var sportIcon: String {

        match.sport.type?.iconName
        ?? "sportscourt.fill"
    }

    private var dayText: String {

        let calendar = Calendar.current

        if calendar.isDateInToday(
            match.startsAt
        ) {

            return "Today"

        } else if calendar.isDateInTomorrow(
            match.startsAt
        ) {

            return "Tomorrow"

        } else {

            let formatter = DateFormatter()

            formatter.dateFormat = "d MMM"

            return formatter.string(
                from: match.startsAt
            )
        }
    }

    private var timeText: String {

        let formatter = DateFormatter()

        formatter.dateFormat = "h:mm a"

        return formatter.string(
            from: match.startsAt
        )
    }

    // MARK: - Body

    var body: some View {

        HStack {

            matchInfoSection

            Spacer()

            iconSection
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity)
        .background {

            if match.wasMVP {

                PatternBackground(
                    symbol: "crown.fill",
                    color: .yellow,
                    opacity: 0.2
                )
                .rotationEffect(.degrees(-18))
                .scaleEffect(1.2)
                .frame(height: 170)
                .clipped()
            }
        }
        .frame(height: 170)
        .glassEffect(
            .regular
                .tint(
                    match.wasMVP
                    ? .yellow.opacity(0.18)
                    : Color("AccentColor")
                        .opacity(0.18)
                )
                .interactive(true),

            in: RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
    }

    // MARK: - Match Info

    private var matchInfoSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(
                match.sport.name.capitalized
            )
            .font(.title3)
            .bold()

            HStack {

                Text(dayText)

                Image(systemName: "circle.fill")
                    .font(.system(size: 7))

                Text(timeText)
            }
            .font(.subheadline)
            .bold()
            .foregroundStyle(.secondary)

            rewardsSection
        }
    }

    // MARK: - Rewards

    private var rewardsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack(spacing: 6) {

                Image(
                    systemName: "arrow.up.right"
                )
                .font(.system(size: 13))

                Text(
                    "+\(match.ratingChange) Rating"
                )
                .bold()
            }
            .foregroundStyle(.green)

            HStack(spacing: 6) {

                Image(
                    systemName: "sparkles"
                )
                .font(.system(size: 13))

                Text(
                    "+\(match.perfPointsEarned) Points"
                )
                .bold()
            }
            .foregroundStyle(Color("AccentColor"))

            if match.wasMVP {

                HStack(spacing: 6) {

                    Image(
                        systemName: "crown.fill"
                    )

                    Text("MVP")
                        .bold()
                }
                .foregroundStyle(.yellow)
            }
        }
        .font(.subheadline)
    }

    // MARK: - Icon Section

    private var iconSection: some View {

        VStack(spacing: 14) {

            if match.wasMVP {

                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.yellow)
            }

            Image(systemName: sportIcon)
                .font(.system(size: 58))
                .foregroundStyle(
                    match.wasMVP
                    ? .yellow
                    : Color("AccentColor")
                )
        }
    }
}
