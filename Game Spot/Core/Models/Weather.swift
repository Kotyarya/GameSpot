import Foundation

struct WeatherResponse: Decodable {
    let hourly: HourlyWeather
}

struct HourlyWeather: Decodable {
    
    let time: [String]
    
    let temperature2m: [Double]
    let precipitationProbability: [Int]
    let windSpeed10m: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        
        case temperature2m = "temperature_2m"
        case precipitationProbability = "precipitation_probability"
        case windSpeed10m = "wind_speed_10m"
    }
}

struct Weather {
    let temperature: Double
    let windSpeed: Double
    let rainChance: Int
}
