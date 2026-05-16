import Foundation

final class WeatherService: @unchecked Sendable {

    // MARK: - Shared

    static let shared = WeatherService()

    // MARK: - Public

    func fetchWeather(
        latitude: Double,
        longitude: Double,
        date: Date
    ) async throws -> Weather {

        let urlString =
        """
        https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&hourly=temperature_2m,precipitation_probability,wind_speed_10m&forecast_days=7&timezone=auto
        """

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) =
            try await URLSession.shared.data(
                from: url
            )

        let decoded =
            try JSONDecoder().decode(
                WeatherResponse.self,
                from: data
            )

        return try mapClosestWeather(
            from: decoded.hourly,
            targetDate: date
        )
    }

    // MARK: - Mapping

    private func mapClosestWeather(
        from hourly: HourlyWeather,
        targetDate: Date
    ) throws -> Weather {

        let formatter =
            ISO8601DateFormatter()

        var closestIndex = 0

        var smallestDiff =
            Double.infinity

        for (
            index,
            timeString
        ) in hourly.time.enumerated() {

            guard let date =
                formatter.date(
                    from: timeString
                ) else {
                continue
            }

            let diff = abs(
                date.timeIntervalSince(
                    targetDate
                )
            )

            if diff < smallestDiff {

                smallestDiff = diff

                closestIndex = index
            }
        }

        return Weather(
            temperature:
                hourly.temperature2m[
                    closestIndex
                ],

            windSpeed:
                hourly.windSpeed10m[
                    closestIndex
                ],

            rainChance:
                hourly.precipitationProbability[
                    closestIndex
                ]
        )
    }
}
