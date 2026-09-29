#if DEBUG

import SwiftUI

private struct RankBadgesShowcaseView: View {
    private let ratings = [
        0, 400, 800,
        2_000, 3_200, 3_800,
        4_000, 5_200,
        6_000,
        8_000, 9_200,
        10_000
    ]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Ranking System")
                    .font(.largeTitle)
                    .bold()

                Text("League progression based on rating points")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            .padding(.top)

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(ratings, id: \.self) { rating in
                    let rank = RankHelper.getRank(rating: rating)

                    VStack(spacing: 8) {
                        Text(rank.title)
                            .font(.subheadline)
                            .bold()
                            .fontDesign(.rounded)
                            .foregroundStyle(rank.textColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(rank.borderColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(
                                color: rank.textColor.opacity(0.25),
                                radius: 8
                            )

                        Text("\(rating) RP")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white)
    }
}

#Preview("Rank Badges") {
    RankBadgesShowcaseView()
}

#Preview("Pattern Background") {
    PatternBackground(
        symbol: "soccerball",
        color: .purple,
        opacity: 0.18
    )
}

#endif
