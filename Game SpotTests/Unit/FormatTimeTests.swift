//
//  FormatTimeTests.swift
//  Game SpotTests
//
//  Validates park opening-hours string formatting helper.
//

import XCTest
@testable import Game_Spot

final class FormatTimeTests: XCTestCase {

    func testFormatTimeTrimsSeconds() {
        XCTAssertEqual(
            formatTime("09:30:00"),
            "09:30"
        )
    }

    func testFormatTimeReturnsPlaceholderForNil() {
        XCTAssertEqual(
            formatTime(nil),
            "--:--"
        )
    }

    func testFormatTimeReturnsPlaceholderForInvalidInput() {
        XCTAssertEqual(
            formatTime("invalid"),
            "--:--"
        )
    }

    func testFormatTimePreservesHourMinuteOnlyInput() {
        XCTAssertEqual(
            formatTime("22:15"),
            "22:15"
        )
    }
}
