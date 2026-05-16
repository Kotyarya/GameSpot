//
//  RankHelperTests.swift
//  Game SpotTests
//
//  Validates competitive rank calculation used across profile and MVP UI.
//

import XCTest
@testable import Game_Spot

final class RankHelperTests: XCTestCase {

    // MARK: - Bronze League

    func testRankCalculationForZeroRating() {
        let rank = RankHelper.getRank(rating: 0)

        XCTAssertTrue(rank.title.contains("Bronze"))
        XCTAssertTrue(rank.title.contains("I"))
    }

    func testRankCalculationForMidBronzeRating() {
        let rank = RankHelper.getRank(rating: 450)

        XCTAssertTrue(rank.title.contains("Bronze"))
        XCTAssertTrue(rank.title.contains("II"))
    }

    // MARK: - Higher Leagues

    func testRankCalculationForSilverRating() {
        let rank = RankHelper.getRank(rating: 2_100)

        XCTAssertTrue(rank.title.contains("Silver"))
    }

    func testRankCalculationForGoldRating() {
        let rank = RankHelper.getRank(rating: 4_200)

        XCTAssertTrue(rank.title.contains("Gold"))
    }

    func testRankCalculationForDiamondRating() {
        let rank = RankHelper.getRank(rating: 6_500)

        XCTAssertTrue(rank.title.contains("Diamond"))
    }

    func testRankCalculationForRubyRating() {
        let rank = RankHelper.getRank(rating: 8_800)

        XCTAssertTrue(rank.title.contains("Ruby"))
    }

    // MARK: - King / Edge Cases

    func testRankCalculationForHighRating() {
        let rank = RankHelper.getRank(rating: 10_500)

        XCTAssertEqual(rank.title, RankLeague.king.name)
    }

    func testRankCalculationClampsNegativeRating() {
        let rank = RankHelper.getRank(rating: -100)

        XCTAssertTrue(rank.title.contains("Bronze"))
    }

    func testRankDivisionProgressionWithinLeague() {
        let divisionI = RankHelper.getRank(rating: 0)
        let divisionV = RankHelper.getRank(rating: 1_600)

        XCTAssertTrue(divisionI.title.hasSuffix("I"))
        XCTAssertTrue(divisionV.title.hasSuffix("V"))
    }
}
