//
//  ParkHoursLogicTests.swift
//  Game SpotTests
//
//  Validates park open/closed logic mirrored from ParkInfoView.
//

import XCTest
@testable import Game_Spot

final class ParkHoursLogicTests: XCTestCase {

    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testIsParkOpenDuringBusinessHours() {
        // 2026-05-15 is a Friday -> normalized day 5
        let now = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 15,
                hour: 14,
                minute: 0
            )
        )!

        let hours = [
            TestFixtures.parkHour(
                dayOfWeek: 5,
                openHour: "09:00:00",
                closeTime: "22:00:00"
            )
        ]

        XCTAssertTrue(
            ParkHoursLogic.isParkOpen(
                hours: hours,
                now: now,
                calendar: calendar
            )
        )
    }

    func testIsParkOpenReturnsFalseWhenClosedForDay() {
        let now = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 15,
                hour: 14,
                minute: 0
            )
        )!

        let hours = [
            TestFixtures.parkHour(
                dayOfWeek: 5,
                openHour: nil,
                closeTime: nil,
                isClosed: true
            )
        ]

        XCTAssertFalse(
            ParkHoursLogic.isParkOpen(
                hours: hours,
                now: now,
                calendar: calendar
            )
        )
    }

    func testIsParkOpenReturnsFalseBeforeOpening() {
        let now = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 15,
                hour: 7,
                minute: 30
            )
        )!

        let hours = [
            TestFixtures.parkHour(
                dayOfWeek: 5,
                openHour: "09:00:00",
                closeTime: "22:00:00"
            )
        ]

        XCTAssertFalse(
            ParkHoursLogic.isParkOpen(
                hours: hours,
                now: now,
                calendar: calendar
            )
        )
    }

    func testTodayHoursLabelForOpenDay() {
        let now = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 15,
                hour: 12,
                minute: 0
            )
        )!

        let hours = [
            TestFixtures.parkHour(
                dayOfWeek: 5,
                openHour: "09:00:00",
                closeTime: "22:00:00"
            )
        ]

        XCTAssertEqual(
            ParkHoursLogic.todayHoursLabel(
                from: hours,
                now: now,
                calendar: calendar
            ),
            "09:00-22:00"
        )
    }

    func testTodayHoursLabelForClosedDay() {
        let now = calendar.date(
            from: DateComponents(
                year: 2026,
                month: 5,
                day: 15,
                hour: 12,
                minute: 0
            )
        )!

        let hours = [
            TestFixtures.parkHour(
                dayOfWeek: 5,
                isClosed: true
            )
        ]

        XCTAssertEqual(
            ParkHoursLogic.todayHoursLabel(
                from: hours,
                now: now,
                calendar: calendar
            ),
            "Closed"
        )
    }
}
