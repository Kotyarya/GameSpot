import Foundation

struct GameSection: Identifiable {

    let date: Date

    let title: String

    let games: [Game]

    var id: Date { date }
}

enum GameSectionBuilder {

    static func sections(
        for games: [Game],
        calendar: Calendar = .current,
        now: Date = Date(),
        locale: Locale = .current
    ) -> [GameSection] {

        let groupedGames = Dictionary(
            grouping: games
        ) { game in
            calendar.startOfDay(for: game.startsAt)
        }

        return groupedGames.keys.sorted().map { date in
            GameSection(
                date: date,
                title: title(
                    for: date,
                    calendar: calendar,
                    now: now,
                    locale: locale
                ),
                games: groupedGames[date, default: []]
                    .sorted { $0.startsAt < $1.startsAt }
            )
        }
    }

    static func title(
        for date: Date,
        calendar: Calendar = .current,
        now: Date = Date(),
        locale: Locale = .current
    ) -> String {

        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        }

        if let tomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: now
        ), calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }

        if let yesterday = calendar.date(
            byAdding: .day,
            value: -1,
            to: now
        ), calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }
}
