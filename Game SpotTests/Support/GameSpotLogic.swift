//
//  GameSpotLogic.swift
//  Game SpotTests
//
//  Test-only helpers that mirror algorithms embedded in SwiftUI views
//  (`GameCard`, `GameInfoView`, `JoinGameSheetView`, `GamesView`).
//  Production code is unchanged; these functions document and verify
//  the same behavioral contracts used by the UI layer.
//

import Foundation
@testable import Game_Spot

enum GameSpotLogic {

    // MARK: - Live State (GameCard / GameInfoView)

    /// Mirrors `GameCard.isActuallyLive` and `GameInfoView.isActuallyLive`.
    static func isActuallyLive(
        startsAt: Date,
        durationMinutes: Int,
        isFinished: Bool,
        now: Date = Date()
    ) -> Bool {
        guard !isFinished else {
            return false
        }

        let endDate = startsAt.addingTimeInterval(
            Double(durationMinutes * 60)
        )

        return now >= startsAt && now <= endDate
    }

    static func isActuallyLive(game: Game, now: Date = Date()) -> Bool {
        isActuallyLive(
            startsAt: game.startsAt,
            durationMinutes: game.durationMinutes,
            isFinished: game.isFinished,
            now: now
        )
    }

    static func isActuallyLive(
        details: GameDetails,
        now: Date = Date()
    ) -> Bool {
        isActuallyLive(
            startsAt: details.startsAt,
            durationMinutes: details.durationMinutes,
            isFinished: details.isFinished,
            now: now
        )
    }

    // MARK: - Game Card State (GameCard.state)

    static func gameCardState(
        game: Game,
        now: Date = Date()
    ) -> GameCardState {
        if game.isFinished {
            return .finished
        }

        if isActuallyLive(game: game, now: now) {
            return .live
        }

        if game.joinedPlayers >= game.maxPlayers {
            return .full
        }

        return .open
    }

    // MARK: - Game Info Status (GameInfoView.gameStatus)

    static func gameStatus(
        details: GameDetails?,
        now: Date = Date()
    ) -> String {
        guard let details else {
            return "Open"
        }

        if details.isFinished {
            return "Finished"
        }

        if isActuallyLive(details: details, now: now) {
            return "Live"
        }

        if details.joinedPlayers >= details.maxPlayers {
            return "Full"
        }

        return "Open"
    }

    // MARK: - Countdown (GameInfoView.countdownText)

    static func countdownText(
        startsAt: Date?,
        from now: Date
    ) -> String {
        guard let startsAt else {
            return "--:--:--"
        }

        let totalSeconds = Int(
            startsAt.timeIntervalSince(now)
        )

        if totalSeconds <= 0 {
            return "00:00:00"
        }

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(
            format: "%02d:%02d:%02d",
            hours,
            minutes,
            seconds
        )
    }

    // MARK: - Open Slot (GameInfoView.isOpen)

    static func isGameOpen(
        details: GameDetails?,
        now: Date = Date()
    ) -> Bool {
        guard let details else {
            return false
        }

        return !details.isFinished
            && !isActuallyLive(details: details, now: now)
            && details.joinedPlayers < details.maxPlayers
    }

    // MARK: - Countdown Visibility (GameInfoView.shouldShowCountdown)

    static func shouldShowCountdown(
        details: GameDetails?,
        now: Date = Date()
    ) -> Bool {
        guard let details else {
            return false
        }

        if isActuallyLive(details: details, now: now) {
            return true
        }

        let diff = details.startsAt.timeIntervalSince(now)
        return diff > 0 && diff <= 86_400
    }

    // MARK: - Teams (JoinGameSheetView)

    static func teamLimit(maxPlayers: Int) -> Int {
        maxPlayers / 2
    }

    static func alphaPlayers(from players: [Player]) -> [Player] {
        players.filter { $0.team == .alpha }
    }

    static func betaPlayers(from players: [Player]) -> [Player] {
        players.filter { $0.team == .beta }
    }

    static func isUserJoined(
        players: [Player],
        userId: UUID
    ) -> Bool {
        players.contains { $0.id == userId }
    }

    // MARK: - Games List Sections (GamesView.sections)

    static func sectionTitle(
        for date: Date,
        calendar: Calendar = .current
    ) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }

        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: date)
    }

    static func groupedSectionTitles(
        for games: [Game],
        calendar: Calendar = .current
    ) -> [String] {
        let grouped = Dictionary(grouping: games) { game in
            calendar.startOfDay(for: game.startsAt)
        }

        return grouped.keys.sorted().map { date in
            sectionTitle(for: date, calendar: calendar)
        }
    }
}
