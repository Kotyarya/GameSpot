//
//  GameModelDecodingTests.swift
//  Game SpotTests
//
//  Ensures API JSON maps correctly into domain models.
//

import XCTest
@testable import Game_Spot

final class GameModelDecodingTests: XCTestCase {

    func testGameDecodesFromJSON() throws {
        let startsAt = Date(timeIntervalSince1970: 1_700_000_000)
        let game = TestFixtures.game(startsAt: startsAt)

        XCTAssertEqual(game.id, TestFixtures.gameId)
        XCTAssertEqual(game.sport.name, "football")
        XCTAssertEqual(game.durationMinutes, 60)
        XCTAssertEqual(game.maxPlayers, 10)
        XCTAssertFalse(game.isFinished)
    }

    func testGameDetailsDecodesPlayersAndPark() throws {
        let details = TestFixtures.gameDetails(
            startsAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        XCTAssertEqual(details.players.count, 2)
        XCTAssertEqual(details.park.name, "Central Park")
        XCTAssertTrue(details.park.hasLighting)
    }

    func testTeamDecodesRawValues() throws {
        let player = TestFixtures.player(team: .beta)

        XCTAssertEqual(player.team, .beta)
        XCTAssertEqual(player.team.rawValue, "Team Beta")
    }

    func testGamesModeEquality() {
        let parkA = UUID()
        let parkB = UUID()

        XCTAssertEqual(GamesMode.myGames, GamesMode.myGames)
        XCTAssertEqual(
            GamesMode.park(id: parkA),
            GamesMode.park(id: parkA)
        )
        XCTAssertNotEqual(
            GamesMode.park(id: parkA),
            GamesMode.park(id: parkB)
        )
        XCTAssertNotEqual(GamesMode.myGames, GamesMode.park(id: parkA))
    }
}
