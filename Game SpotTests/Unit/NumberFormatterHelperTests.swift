//
//  NumberFormatterHelperTests.swift
//  Game SpotTests
//
//  Validates rating and stat display formatting on the profile screen.
//

import XCTest
@testable import Game_Spot

final class NumberFormatterHelperTests: XCTestCase {

    // MARK: - Plain Values

    func testFormatRatingForSmallValues() {
        XCTAssertEqual(
            NumberFormatterHelper.formatRating(42),
            "42"
        )
    }

    func testFormatRatingForZero() {
        XCTAssertEqual(
            NumberFormatterHelper.formatRating(0),
            "0"
        )
    }

    func testFormatRatingForNegativeValues() {
        XCTAssertEqual(
            NumberFormatterHelper.formatRating(-150),
            "-150"
        )
    }

    // MARK: - Abbreviated Values

    func testFormatRatingForThousands() {
        XCTAssertEqual(
            NumberFormatterHelper.formatRating(1_500),
            "1.5K"
        )
    }

    func testFormatRatingForMillions() {
        XCTAssertEqual(
            NumberFormatterHelper.formatRating(2_500_000),
            "2.5M"
        )
    }

    func testFormatRatingForBillions() {
        XCTAssertEqual(
            NumberFormatterHelper.formatRating(3_200_000_000),
            "3.2B"
        )
    }

    func testFormatRatingForLargeRoundThousands() {
        XCTAssertEqual(
            NumberFormatterHelper.formatRating(10_000),
            "10K"
        )
    }
}
