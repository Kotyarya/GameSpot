import Foundation

struct Sport: Decodable, Identifiable, Hashable {
    let id: UUID
    let name: String
    
    var type: SportType? {
        SportType(rawValue: name.lowercased())
    }
}

enum SportType: String {
    case football
    case basketball
    case volleyball
    
    var iconName: String {
        switch self {
        case .basketball: return "basketball.fill"
        case .football: return "soccerball"
        case .volleyball: return "volleyball.fill"
        }
    }
}
