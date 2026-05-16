//
//  ParkHoursLogic.swift
//  Game SpotTests
//
//  Mirrors `ParkInfoView.isParkOpen` and `todayHours` behavior.
//

import Foundation
@testable import Game_Spot

enum ParkHoursLogic {

    // MARK: - Open State (ParkInfoView.isParkOpen)

    static func isParkOpen(
        hours: [ParkHour],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        let weekday = calendar.component(.weekday, from: now)
        let normalizedDay = weekday == 1 ? 7 : weekday - 1

        guard let today = hours.first(where: { $0.dayOfWeek == normalizedDay }) else {
            return false
        }

        if today.isClosed {
            return false
        }

        guard let open = today.openHour,
              let close = today.closeTime else {
            return false
        }

        let openParts = formatTime(open).split(separator: ":")
        let closeParts = formatTime(close).split(separator: ":")

        guard let openHour = Int(openParts[0]),
              let openMinute = Int(openParts[1]),
              let closeHour = Int(closeParts[0]),
              let closeMinute = Int(closeParts[1]) else {
            return false
        }

        let nowHour = calendar.component(.hour, from: now)
        let nowMinute = calendar.component(.minute, from: now)

        let nowTotal = nowHour * 60 + nowMinute
        let openTotal = openHour * 60 + openMinute
        let closeTotal = closeHour * 60 + closeMinute

        return nowTotal >= openTotal && nowTotal <= closeTotal
    }

    // MARK: - Today Hours Label (ParkInfoView.todayHours)

    static func todayHoursLabel(
        from hours: [ParkHour],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> String {
        let weekday = calendar.component(.weekday, from: now)
        let normalizedDay = weekday == 1 ? 7 : weekday - 1

        guard let today = hours.first(where: { $0.dayOfWeek == normalizedDay }) else {
            return "--:--"
        }

        if today.isClosed {
            return "Closed"
        }

        let open = formatTime(today.openHour ?? "--:--")
        let close = formatTime(today.closeTime ?? "--:--")
        return "\(open)-\(close)"
    }
}
