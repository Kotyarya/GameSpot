import SwiftUI
internal import Auth

@MainActor
struct ProfileView: View {

    // MARK: - View Model

    @StateObject private var viewModel =
        ProfileViewModel()

    // MARK: - Environment

    @EnvironmentObject var session:
        SessionManager

    // MARK: - Overall Rank

    private var rank: Rank {

        let rating =
            viewModel.profile?.rating ?? 0

        return RankHelper.getRank(
            rating: rating
        )
    }

    // MARK: - Helpers

    private func sportRank(
        for rating: Int
    ) -> Rank {

        RankHelper.getRank(
            rating: rating
        )
    }

    private var fallbackIcon: some View {

        Image(
            systemName: "person.crop.circle.fill"
        )
        .resizable()
        .scaledToFit()
        .padding(18)
        .foregroundStyle(rank.textColor)
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
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {

        if viewModel.isLoading {

            LoadingView()
                .transition(
                    .opacity.combined(
                        with: .scale(scale: 0.98)
                    )
                )

        } else if let error =
                    viewModel.errorMessage {

            Text(error)

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

    private var headerSection: some View {

        ZStack {

            rank.backgroundColor

            PatternBackground(
                symbol:
                    viewModel.profile?
                    .favoriteSport?
                    .type?
                    .iconName
                ?? "trophy.fill",

                color: .black,
                opacity: 0.1
            )

            VStack {

                overallRankBadge

                avatarSection

                usernameSection

                globalRatingSection
            }
            .padding(.top, 32)
        }
        .frame(maxHeight: 463)
        .clipped()
        .clipShape(
            RoundedRectangle(
                cornerRadius: 48
            )
        )
    }

    // MARK: - Overall Rank

    private var overallRankBadge: some View {

        VStack(spacing: 8) {

            ZStack {

                Text(rank.title)
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(
                        rank.textColor
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .background(rank.borderColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 12
                )
            )
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {

        ZStack {

            Circle()
                .fill(
                    rank.backgroundColor
                        .opacity(0.25)
                )

            if let urlString =
                viewModel.profile?.avatarUrl,
               let url = URL(string: urlString) {

                AsyncImage(url: url) { image in

                    image
                        .resizable()
                        .scaledToFill()

                } placeholder: {

                    fallbackIcon
                }

            } else {

                fallbackIcon
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay {

            Circle()
                .stroke(
                    rank.borderColor,
                    lineWidth: 2
                )
        }
        .shadow(radius: 6)
        .padding(.top, 12)
    }

    // MARK: - Username

    private var usernameSection: some View {

        Text(
            viewModel.profile?.username
            ?? "Nickname"
        )
        .font(.largeTitle)
        .bold()
    }

    // MARK: - Global Rating

    private var globalRatingSection: some View {

        Gauge(
            value: Double(
                viewModel.profile?.rating ?? 0
            ),

            in: 0...9999
        ) {

            Image(systemName: "trophy.fill")
                .foregroundStyle(rank.textColor)

        } currentValueLabel: {

            Text(
                NumberFormatterHelper
                    .formatRating(
                        viewModel.profile?.rating ?? 0
                    )
            )
            .bold()
            .foregroundStyle(rank.textColor)
        }
        .gaugeStyle(.accessoryCircular)
        .scaleEffect(1.5)
        .padding(.top, 26)
        .tint(rank.textColor)
        .shadow(
            color: rank.textColor.opacity(0.6),
            radius: 12
        )
        .shadow(
            color: rank.textColor.opacity(0.3),
            radius: 20
        )
    }

    // MARK: - Sections

    private var contentSections: some View {

        VStack(spacing: 32) {

            overallProfileSection

            recentMatchesSection

            sportStatsSection

            signOutSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
    }

    // MARK: - Overall Profile

    private var overallProfileSection: some View {

        VStack(alignment: .leading) {

            Text("Overall Profile")
                .font(.largeTitle)
                .bold()

            VStack(spacing: 24) {

                ZStack {

                    Text(rank.title)
                        .font(.title)
                        .bold()
                        .fontDesign(.rounded)
                        .foregroundStyle(
                            rank.textColor
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }
                .background(rank.borderColor)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                )

                HStack(spacing: 0) {

                    statItem(
                        value:
                            NumberFormatterHelper
                            .formatRating(
                                viewModel.profile?
                                    .gamesPlayed ?? 0
                            ),

                        title: "Matches"
                    )

                    statItem(
                        value:
                            NumberFormatterHelper
                            .formatRating(
                                viewModel.profile?
                                    .mvpCount ?? 0
                            ),

                        title: "MVP"
                    )

                    statItem(
                        value:
                            NumberFormatterHelper
                            .formatRating(
                                viewModel.profile?
                                    .perfPoints ?? 0
                            ),

                        title: "Points"
                    )
                }
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .glassEffect(
                .regular
                    .tint(.clear)
                    .interactive(true),

                in: RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
        }
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

        VStack(spacing: 32) {

            ForEach(viewModel.stats) { stat in

                sportStatCard(stat)
            }
        }
    }

    // MARK: - Sport Stat Card

    private func sportStatCard(
        _ stat: UserSportStats
    ) -> some View {

        let sportRank =
            sportRank(for: stat.rating)

        return VStack(alignment: .leading) {

            Text(
                "\(stat.sport.name.capitalized)"
            )
            .font(.largeTitle)
            .bold()

            VStack(spacing: 28) {

                sportGaugeSection(
                    stat: stat,
                    rank: sportRank
                )

                sportRankSection(
                    rank: sportRank
                )

                sportStatsItems(
                    stat: stat
                )
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .glassEffect(
                .regular
                    .tint(
                        sportRank
                            .backgroundColor
                            .opacity(0.15)
                    )
                    .interactive(true),

                in: RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
        }
    }

    // MARK: - Sport Gauge

    private func sportGaugeSection(
        stat: UserSportStats,
        rank: Rank
    ) -> some View {

        Gauge(
            value: Double(stat.rating),
            in: 0...9999
        ) {

            Image(
                systemName: "trophy.fill"
            )
            .foregroundStyle(
                rank.borderColor
            )

        } currentValueLabel: {

            Text(
                NumberFormatterHelper
                    .formatRating(
                        stat.rating
                    )
            )
            .bold()
            .foregroundStyle(
                rank.borderColor
            )
        }
        .gaugeStyle(.accessoryCircular)
        .scaleEffect(1.45)
        .padding(.top, 20)
        .tint(rank.borderColor)
        .shadow(
            color:
                rank.textColor
                .opacity(0.3),

            radius: 10
        )
    }

    // MARK: - Sport Rank

    private func sportRankSection(
        rank: Rank
    ) -> some View {

        ZStack {

            Text(rank.title)
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(
                    rank.textColor
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
        }
        .background(
            rank.borderColor
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10
            )
        )
        .shadow(
            color:
                rank.textColor
                .opacity(0.25),

            radius: 8
        )
    }

    // MARK: - Sport Stats Items

    private func sportStatsItems(
        stat: UserSportStats
    ) -> some View {

        HStack(spacing: 0) {

            statItem(
                value:
                    NumberFormatterHelper
                    .formatRating(
                        stat.gamesPlayed
                    ),

                title: "Matches"
            )

            statItem(
                value:
                    NumberFormatterHelper
                    .formatRating(
                        stat.mvpCount
                    ),

                title: "MVP"
            )

            statItem(
                value:
                    NumberFormatterHelper
                    .formatRating(
                        stat.perfPoints
                    ),

                title: "Points"
            )
        }
    }

    // MARK: - Sign Out

    private var signOutSection: some View {

        Button {

            Task {
                await session.signOut()
            }

        } label: {

            HStack(
                alignment: .center,
                spacing: 6
            ) {

                Image(
                    systemName:
                        "rectangle.portrait.and.arrow.right"
                )
                .font(.system(size: 18))

                Text("Sign Out")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.glassProminent)
        .tint(.red.opacity(0.2))
        .foregroundStyle(
            .red
        )
    }

    // MARK: - Stat Item

    @ViewBuilder
    private func statItem(
        value: String,
        title: String
    ) -> some View {

        VStack {

            Text(value)
                .font(.title)
                .bold()

            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
