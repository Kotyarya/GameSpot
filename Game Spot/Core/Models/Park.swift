import Foundation
import CoreLocation

// MARK: Park

struct Park: Decodable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let address: String?
    let isActive: Bool
    let hasLighting: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case address
        case isActive = "is_active"
        case hasLighting = "has_lighting"
    }
}

// MARK: Park Details

struct ParkDetails: Decodable {
    let park: Park
    let sports: [Sport]
    let hours: [ParkHour]
    let images: [ParkImage]
    let rating: ParkRating?
}

// MARK: Park Hour

struct ParkHour: Decodable, Identifiable {
    let id: Int
    let dayOfWeek: Int
    let openHour: String?
    let closeTime: String?
    let isClosed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case dayOfWeek = "day_of_week"
        case openHour = "open_hour"
        case closeTime = "close_time"
        case isClosed = "is_closed"
    }
}

// MARK: Park Image

struct ParkImage: Decodable, Identifiable {
    let id: Int
    let imageUrl: String
    let isMain: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageUrl = "image_url"
        case isMain = "is_main"
    }
}

// MARK: Park Rating

struct ParkRating: Decodable {
    let qualityAvg: Double
    let qualityCount: Int
    
    let facilitiesAvg: Double
    let facilitiesCount: Int
    
    let activityAvg: Double
    let activityCount: Int
    
    let overallAvg: Double
    
    enum CodingKeys: String, CodingKey {
        case qualityAvg = "quality_avg"
        case qualityCount = "quality_count"
        
        case facilitiesAvg = "facilities_avg"
        case facilitiesCount = "facilities_count"
        
        case activityAvg = "activity_avg"
        case activityCount = "activity_count"
        
        case overallAvg = "overall_avg"
    }
}

// MARK: Park Short

struct ParkShort: Decodable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let hasLighting: Bool
    let overallAvg: Double
}
