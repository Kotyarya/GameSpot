//
//  GameStateLogicTests.swift
//  Game SpotTests
//
//  Validates live-game detection, card states, countdown, and team filtering.
//  Logic mirrors `GameCard`, `GameInfoView`, `JoinGameSheetView`, and `GamesView`.
//

import XCTest
@testable import Game_Spot

final class GameStateLogicTests: XCTestCase {

    private var calendar: Calendar!
    private var now: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        now = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 15,
                hour: 12,
                minute: 0
            )
        )!
    }

    // MARK: - Live Detection

    func testIsActuallyLiveWhenGameIsInProgress() {
        let startsAt = now.addingTimeInterval(-30 * 60)
        let game = TestFixtures.game(
            startsAt: startsAt,
            durationMinutes: 90,
            isFinished: false
        )

        XCTAssertTrue(
            GameSpotLogic.isActuallyLive(
                game: game,
                now: now
            )
        )
    }

    func testIsActuallyLiveReturnsFalseBeforeStart() {
        let startsAt = now.addingTimeInterval(60 * 60)
        let game = TestFixtures.game(startsAt: startsAt)

        XCTAssertFalse(
            GameSpotLogic.isActuallyLive(
                game: game,
                now: now
            )
        )
    }

    func testIsActuallyLiveReturnsFalseAfterEnd() {
        let startsAt = now.addingTimeInterval(-3 * 60 * 60)
        let game = TestFixtures.game(
            startsAt: startsAt,
            durationMinutes: 60,
            isFinished: false
        )

        XCTAssertFalse(
            GameSpotLogic.isActuallyLive(
                game: game,
                now: now
            )
        )
    }

    func testIsActuallyLiveReturnsFalseWhenFinished() {
        let startsAt = now.addingTimeInterval(-15 * 60)
        let game = TestFixtures.game(
            startsAt: startsAt,
            isFinished: true
        )

        XCTAssertFalse(
            GameSpotLogic.isActuallyLive(
                game: game,
                now: now
            )
        )
    }

    // MARK: - Game Card State

    func testGameCardStateOpen() {
        let game = TestFixtures.game(
            startsAt: now.addingTimeInterval(3_600),
            maxPlayers: 10, joinedPlayers: 2
        )

        XCTAssertEqual(
            GameSpotLogic.gameCardState(game: game, now: now),
            .open
        )
    }

    func testGameCardStateFull() {
        let game = TestFixtures.game(
            startsAt: now.addingTimeInterval(3_600),
            maxPlayers: 10, joinedPlayers: 10
        )

        XCTAssertEqual(
            GameSpotLogic.gameCardState(game: game, now: now),
            .full
        )
    }

    func testGameCardStateLive() {
        let game = TestFixtures.game(
            startsAt: now.addingTimeInterval(-20 * 60),
            durationMinutes: 60,
            maxPlayers: 10, joinedPlayers: 6
        )

        XCTAssertEqual(
            GameSpotLogic.gameCardState(game: game, now: now),
            .live
        )
    }

    func testGameCardStateFinished() {
        let game = TestFixtures.game(
            startsAt: now.addingTimeInterval(-3_600),
            isFinished: true
        )

        XCTAssertEqual(
            GameSpotLogic.gameCardState(game: game, now: now),
            .finished
        )
    }

    // MARK: - Game Status String

    func testGameStatusReturnsLive() {
        let details = TestFixtures.gameDetails(
            startsAt: now.addingTimeInterval(-10 * 60),
            durationMinutes: 60,
            maxPlayers: 10, joinedPlayers: 4
        )

        XCTAssertEqual(
            GameSpotLogic.gameStatus(details: details, now: now),
            "Live"
        )
    }

    func testGameStatusReturnsFull() {
        let details = TestFixtures.gameDetails(
            startsAt: now.addingTimeInterval(3_600),
            maxPlayers: 10, joinedPlayers: 10
        )

        XCTAssertEqual(
            GameSpotLogic.gameStatus(details: details, now: now),
            "Full"
        )
    }

    func testGameStatusReturnsFinished() {
        let details = TestFixtures.gameDetails(
            startsAt: now.addingTimeInterval(-3_600),
            isFinished: true
        )

        XCTAssertEqual(
            GameSpotLogic.gameStatus(details: details, now: now),
            "Finished"
        )
    }

    func testGameStatusReturnsMVPVotingBeforeFinishedLabel() {
        let details = TestFixtures.gameDetails(
            startsAt: now.addingTimeInterval(-3_600),
            isFinished: true,
            mvpVotingOpen: true
        )

        XCTAssertEqual(
            GameSpotLogic.gameStatus(details: details, now: now),
            "MVP Voting"
        )
    }

    func testGameStatusReturnsCompletedAfterProcessing() {
        let details = TestFixtures.gameDetails(
            startsAt: now.addingTimeInterval(-3_600),
            isFinished: true,
            isProcessed: true
        )

        XCTAssertEqual(
            GameSpotLogic.gameStatus(details: details, now: now),
            "Completed"
        )
    }

    // MARK: - Countdown

    func testCountdownTextFormatsRemainingTime() {
        let startsAt = now.addingTimeInterval(3_661)

        XCTAssertEqual(
            GameSpotLogic.countdownText(
                startsAt: startsAt,
                from: now
            ),
            "01:01:01"
        )
    }

    func testCountdownTextReturnsZerosWhenStarted() {
        let startsAt = now.addingTimeInterval(-30)

        XCTAssertEqual(
            GameSpotLogic.countdownText(
                startsAt: startsAt,
                from: now
            ),
            "00:00:00"
        )
    }

    func testCountdownTextReturnsPlaceholderWhenMissingDate() {
        XCTAssertEqual(
            GameSpotLogic.countdownText(
                startsAt: nil,
                from: now
            ),
            "--:--:--"
        )
    }

    func testShouldShowCountdownWithinTwentyFourHours() {
        let details = TestFixtures.gameDetails(
            startsAt: now.addingTimeInterval(12 * 3_600)
        )

        XCTAssertTrue(
            GameSpotLogic.shouldShowCountdown(
                details: details,
                now: now
            )
        )
    }

    func testShouldShowCountdownFalseBeyondTwentyFourHours() {
        let details = TestFixtures.gameDetails(
            startsAt: now.addingTimeInterval(30 * 3_600)
        )

        XCTAssertFalse(
            GameSpotLogic.shouldShowCountdown(
                details: details,
                now: now
            )
        )
    }

    // MARK: - Open State

    func testIsGameOpenWhenSlotsAvailable() {
        let details = TestFixtures.gameDetails(
            startsAt: now.addingTimeInterval(3_600),
            maxPlayers: 10, joinedPlayers: 3
        )

        XCTAssertTrue(
            GameSpotLogic.isGameOpen(
                details: details,
                now: now
            )
        )
    }

    func testIsGameOpenFalseWhenFull() {
        let details = TestFixtures.gameDetails(
            startsAt: now.addingTimeInterval(3_600),
            maxPlayers: 10, joinedPlayers: 10
        )

        XCTAssertFalse(
            GameSpotLogic.isGameOpen(
                details: details,
                now: now
            )
        )
    }

    // MARK: - Teams

    func testTeamFilteringSeparatesAlphaAndBeta() {
        let alpha = TestFixtures.player(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            team: .alpha
        )
        let beta = TestFixtures.player(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            team: .beta
        )
        let players = [alpha, beta]

        XCTAssertEqual(
            GameSpotLogic.alphaPlayers(from: players).count,
            1
        )
        XCTAssertEqual(
            GameSpotLogic.betaPlayers(from: players).count,
            1
        )
    }

    func testTeamLimitIsHalfOfMaxPlayers() {
        XCTAssertEqual(
            GameSpotLogic.teamLimit(maxPlayers: 10),
            5
        )
    }

    func testIsUserJoinedDetectsCurrentPlayer() {
        let userId = TestFixtures.userId
        let players = [TestFixtures.player(id: userId)]

        XCTAssertTrue(
            GameSpotLogic.isUserJoined(
                players: players,
                userId: userId
            )
        )
    }

    // MARK: - Section Titles

    func testGroupedSectionsSortByDateAndGamesByStartTime() {
        let today = now!
        let laterToday = now.addingTimeInterval(3_600)
        let tomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: now
        )!

        let games = [
            TestFixtures.game(startsAt: tomorrow),
            TestFixtures.game(startsAt: laterToday),
            TestFixtures.game(startsAt: today)
        ]

        let sections = GameSectionBuilder.sections(
            for: games,
            calendar: calendar,
            now: now,
            locale: Locale(identifier: "en_US_POSIX")
        )

        XCTAssertEqual(sections.map(\.title), ["Today", "Tomorrow"])
        XCTAssertEqual(
            sections.first?.games.map(\.startsAt),
            [today, laterToday]
        )
    }

    func testGroupedSectionsUseInjectedTimeZone() {
        var tokyoCalendar = Calendar(identifier: .gregorian)
        tokyoCalendar.timeZone = TimeZone(
            identifier: "Asia/Tokyo"
        )!

        let utcNow = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 15,
                hour: 23,
                minute: 30
            )
        )!
        let tokyoTomorrow = utcNow.addingTimeInterval(16 * 3_600)
        let games = [
            TestFixtures.game(startsAt: utcNow),
            TestFixtures.game(startsAt: tokyoTomorrow)
        ]

        let titles = GameSectionBuilder.sections(
            for: games,
            calendar: tokyoCalendar,
            now: utcNow,
            locale: Locale(identifier: "en_US_POSIX")
        ).map(\.title)

        XCTAssertEqual(titles, ["Today", "Tomorrow"])
    }

    func testGroupedSectionsHandleMidnightBoundary() {
        var losAngelesCalendar = Calendar(identifier: .gregorian)
        losAngelesCalendar.timeZone = TimeZone(
            identifier: "America/Los_Angeles"
        )!

        let localNow = losAngelesCalendar.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 15,
                hour: 23,
                minute: 59,
                second: 30
            )
        )!
        let afterMidnight = localNow.addingTimeInterval(60)

        let titles = GameSectionBuilder.sections(
            for: [
                TestFixtures.game(startsAt: afterMidnight),
                TestFixtures.game(startsAt: localNow)
            ],
            calendar: losAngelesCalendar,
            now: localNow,
            locale: Locale(identifier: "en_US_POSIX")
        ).map(\.title)

        XCTAssertEqual(titles, ["Today", "Tomorrow"])
    }

    func testSectionTitleKeepsDayMonthFormatOutsideRelativeRange() {
        let futureDate = calendar.date(
            byAdding: .day,
            value: 5,
            to: now
        )!

        let title = GameSectionBuilder.title(
            for: futureDate,
            calendar: calendar,
            now: now,
            locale: Locale(identifier: "en_US_POSIX")
        )

        XCTAssertEqual(title, "20 May")
    }
}
