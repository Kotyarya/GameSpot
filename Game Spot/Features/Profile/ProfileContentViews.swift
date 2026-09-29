import SwiftUI

struct ProfileAvatarView: View {

    let username: String
    let avatarURL: String?
    let rank: Rank

    var body: some View {

        AsyncImage(
            url: URL(string: avatarURL ?? "")
        ) { phase in

            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()

            default:
                Image(
                    systemName: "person.crop.circle.fill"
                )
                .resizable()
                .scaledToFit()
                .padding(18)
                .foregroundStyle(rank.textColor)
            }
        }
        .frame(width: 120, height: 120)
        .background(
            rank.backgroundColor.opacity(0.25)
        )
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(
                    rank.borderColor,
                    lineWidth: 2
                )
        }
        .shadow(radius: 6)
        .accessibilityLabel(
            "\(username) profile photo"
        )
    }
}

struct ProfileHeroView<AvatarContent: View>: View {

    let username: String
    let rating: Int
    let favoriteSportIcon: String

    @ViewBuilder let avatarContent: () -> AvatarContent

    private var rank: Rank {
        RankHelper.getRank(rating: rating)
    }

    var body: some View {

        ZStack {

            rank.backgroundColor

            PatternBackground(
                symbol: favoriteSportIcon,
                color: .black,
                opacity: 0.1
            )

            VStack {

                Text(rank.title)
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(rank.textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(rank.borderColor)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12
                        )
                    )

                avatarContent()
                    .padding(.top, 12)

                Text(username)
                    .font(.largeTitle)
                    .bold()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Gauge(
                    value: Double(rating),
                    in: 0...9999
                ) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(rank.textColor)
                } currentValueLabel: {
                    Text(
                        NumberFormatterHelper
                            .formatRating(rating)
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
}

struct ProfileSummaryCard: View {

    let rating: Int
    let gamesPlayed: Int
    let mvpCount: Int
    let perfPoints: Int

    private var rank: Rank {
        RankHelper.getRank(rating: rating)
    }

    var body: some View {

        VStack(alignment: .leading) {

            Text("Overall Profile")
                .font(.largeTitle)
                .bold()

            VStack(spacing: 24) {

                Text(rank.title)
                    .font(.title)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(rank.textColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(rank.borderColor)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10
                        )
                    )

                HStack(spacing: 0) {
                    metric(value: gamesPlayed, title: "Matches")
                    metric(value: mvpCount, title: "MVP")
                    metric(value: perfPoints, title: "Points")
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

    private func metric(
        value: Int,
        title: String
    ) -> some View {

        VStack {
            Text(
                NumberFormatterHelper
                    .formatRating(value)
            )
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

struct ProfileSportStatsSection: View {

    let stats: [UserSportStats]

    var body: some View {

        VStack(spacing: 32) {
            ForEach(stats) { stat in
                sportStatCard(stat)
            }
        }
    }

    private func sportStatCard(
        _ stat: UserSportStats
    ) -> some View {

        let rank = RankHelper.getRank(
            rating: stat.rating
        )

        return VStack(alignment: .leading) {

            Text(stat.sport.name.capitalized)
                .font(.largeTitle)
                .bold()

            VStack(spacing: 28) {

                Gauge(
                    value: Double(stat.rating),
                    in: 0...9999
                ) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(rank.borderColor)
                } currentValueLabel: {
                    Text(
                        NumberFormatterHelper
                            .formatRating(stat.rating)
                    )
                    .bold()
                    .foregroundStyle(rank.borderColor)
                }
                .gaugeStyle(.accessoryCircular)
                .scaleEffect(1.45)
                .padding(.top, 20)
                .tint(rank.borderColor)
                .shadow(
                    color: rank.textColor.opacity(0.3),
                    radius: 10
                )

                Text(rank.title)
                    .font(.title2)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(rank.textColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(rank.borderColor)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 10
                        )
                    )
                    .shadow(
                        color: rank.textColor.opacity(0.25),
                        radius: 8
                    )

                HStack(spacing: 0) {
                    metric(
                        value: stat.gamesPlayed,
                        title: "Matches"
                    )
                    metric(
                        value: stat.mvpCount,
                        title: "MVP"
                    )
                    metric(
                        value: stat.perfPoints,
                        title: "Points"
                    )
                }
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .glassEffect(
                .regular
                    .tint(
                        rank.backgroundColor.opacity(0.15)
                    )
                    .interactive(true),
                in: RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
        }
    }

    private func metric(
        value: Int,
        title: String
    ) -> some View {

        VStack {
            Text(
                NumberFormatterHelper
                    .formatRating(value)
            )
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
