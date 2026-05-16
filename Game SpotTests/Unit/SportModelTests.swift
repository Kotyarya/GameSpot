//
//  SportModelTests.swift
//  Game SpotTests
//
//  Validates sport type mapping and SF Symbol selection.
//

import XCTest
@testable import Game_Spot

final class SportModelTests: XCTestCase {

    func testSportTypeMapsFootballIcon() {
        let sport = TestFixtures.sport(name: "football")

        XCTAssertEqual(sport.type, .football)
        XCTAssertEqual(sport.type?.iconName, "soccerball")
    }

    func testSportTypeMapsBasketballIcon() {
        let sport = TestFixtures.sport(
            id: TestFixtures.sportBasketballId,
            name: "basketball"
        )

        XCTAssertEqual(sport.type, .basketball)
        XCTAssertEqual(sport.type?.iconName, "basketball.fill")
    }

    func testSportTypeMapsVolleyballIcon() {
        let sport = TestFixtures.sport(name: "volleyball")

        XCTAssertEqual(sport.type, .volleyball)
        XCTAssertEqual(sport.type?.iconName, "volleyball.fill")
    }

    func testSportTypeIsNilForUnknownSport() {
        let sport = TestFixtures.sport(name: "tennis")

        XCTAssertNil(sport.type)
    }
}
