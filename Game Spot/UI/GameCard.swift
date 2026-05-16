import SwiftUI

enum GameCardState {
    case open
    case full
    case live
    case finished
}

struct GameCard: View {

    // MARK: - Properties

    let game: Game

    @EnvironmentObject private var router: AppRouter

    // MARK: - State

    @State private var pulse = false

    // MARK: - Live State

    private var isActuallyLive: Bool {

        guard !game.isFinished else {
            return false
        }

        let endDate =
            game.startsAt.addingTimeInterval(
                Double(game.durationMinutes * 60)
            )

        let currentDate = Date()

        return currentDate >= game.startsAt
            && currentDate <= endDate
    }

    // MARK: - Game State

    private var state: GameCardState {

        if game.isFinished {
            return .finished
        }

        if isActuallyLive {
            return .live
        }

        if game.joinedPlayers >= game.maxPlayers {
            return .full
        }

        return .open
    }

    // MARK: - Colors

    private func foregroundColor() -> Color {

        state != .open
        ? Color("AccentColor")
        : .white
    }

    private var badgeForeground: Color {

        switch state {

        case .open:
            return Color("AccentColor")

        case .live:
            return .red

        case .full:
            return .white

        case .finished:
            return .white.opacity(0.6)
        }
    }

    private var badgeBackground: Color {

        switch state {

        case .open:
            return .white.opacity(0.5)

        case .live:
            return .red.opacity(0.15)

        case .full:
            return Color("AccentColor")

        case .finished:
            return Color("AccentColor")
        }
    }

    // MARK: - Date Formatting

    private var dayText: String {

        let calendar = Calendar.current

        if calendar.isDateInToday(game.startsAt) {

            return "Today"

        } else if calendar.isDateInTomorrow(game.startsAt) {

            return "Tomorrow"

        } else {

            let formatter = DateFormatter()

            formatter.dateFormat = "d MMM"

            return formatter.string(
                from: game.startsAt
            )
        }
    }

    private var timeText: String {

        let formatter = DateFormatter()

        formatter.dateFormat = "h:mm a"

        return formatter.string(
            from: game.startsAt
        )
    }

    // MARK: - Text

    private var stateText: String {

        switch state {

        case .open:
            return "Open"

        case .full:
            return "Full"

        case .live:
            return "Live"

        case .finished:
            return "Finished"
        }
    }

    // MARK: - Sport

    private var sportIcon: String {

        game.sport.type?.iconName
        ?? "sportscourt"
    }

    // MARK: - Body

    var body: some View {

        Button {

            router.push(.game(game.id))

        } label: {

            HStack {

                contentSection

                Spacer()

                sportSection
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
        .opacity(
            state == .finished
            ? 0.4
            : 1
        )
        .frame(maxWidth: .infinity)
        .buttonStyle(.glassProminent)
        .tint(
            Color("AccentColor")
                .opacity(
                    state != .open ? 0.35 : 1
                )
        )
        .buttonBorderShape(
            .roundedRectangle(radius: 24)
        )
    }

    // MARK: - Content

    private var contentSection: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            titleSection

            dateSection

            bottomSection
        }
    }

    // MARK: - Title

    private var titleSection: some View {

        Text(
            game.sport.name.capitalized
        )
        .font(.title2)
        .bold()
        .foregroundStyle(
            foregroundColor()
        )
    }

    // MARK: - Date

    private var dateSection: some View {

        HStack {

            Text(dayText)

            Image(systemName: "circle.fill")
                .font(.system(size: 8))

            Text(timeText)
        }
        .font(.headline)
        .bold()
        .foregroundStyle(
            foregroundColor()
        )
    }

    // MARK: - Bottom

    private var bottomSection: some View {

        HStack {

            playersSection

            statusBadge
        }
        .font(.headline)
        .bold()
        .foregroundStyle(
            foregroundColor()
        )
    }

    // MARK: - Players

    private var playersSection: some View {

        HStack {

            Image(
                systemName:
                    "person.crop.circle"
            )
            .font(.system(size: 22))

            Text(
                "\(game.joinedPlayers)/\(game.maxPlayers)"
            )
        }
    }

    // MARK: - Status Badge

    private var statusBadge: some View {

        HStack(spacing: 6) {

            if state == .live {

                Circle()
                    .fill(.red)
                    .frame(
                        width: 10,
                        height: 10
                    )
                    .opacity(
                        pulse ? 0.2 : 1
                    )
                    .scaleEffect(
                        pulse ? 0.8 : 1
                    )
                    .animation(
                        .easeInOut(duration: 1)
                            .repeatForever(),
                        value: pulse
                    )
            }

            Text(stateText)
                .font(.body)
                .fontWeight(.bold)
        }
        .foregroundStyle(
            badgeForeground
        )
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            badgeBackground
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10
            )
        )
        .onAppear {

            pulse = true
        }
    }

    // MARK: - Sport Icon

    private var sportSection: some View {

        Image(systemName: sportIcon)
            .font(.system(size: 64))
            .foregroundStyle(
                foregroundColor()
            )
    }
}
