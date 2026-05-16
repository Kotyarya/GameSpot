import SwiftUI

enum RankLeague: Int, CaseIterable {
    case bronze = 0
    case silver
    case gold
    case diamond
    case ruby
    case king
    
    var name: String {
        switch self {
        case .bronze: return "🥉 Bronze"
        case .silver: return "🥈 Silver"
        case .gold: return "🥇 Gold"
        case .diamond: return "💎 Diamond"
        case .ruby: return "♦️ Ruby"
        case .king: return "👑 King"
        }
    }
    
    
    var textColor: Color {
        switch self {
        case .bronze: return Color("BronzeRankText")
        case .silver: return Color("SilverRankText")
        case .gold: return Color("GoldRankText")
        case .diamond: return Color("DiamondRankText")
        case .ruby: return Color("RubyRankText")
        case .king: return Color("KingRankText")
        }
    }
    
    
    var backgroundColor: Color {
        switch self {
        case .bronze: return Color("BronzeRankBackground")
        case .silver: return Color("SilverRankBackground")
        case .gold: return Color("GoldRankBackground")
        case .diamond: return Color("DiamondRankBackground")
        case .ruby: return Color("RubyRankBackground")
        case .king: return Color("KingRankBackground")
        }
    }
    
    
    var borderColor: Color {
        switch self {
        case .bronze: return Color("BronzeRankBorder")
        case .silver: return Color("SilverRankBorder")
        case .gold: return Color("GoldRankBorder")
        case .diamond: return Color("DiamondRankBorder")
        case .ruby: return Color("RubyRankBorder")
        case .king: return Color("KingRankBorder")
        }
    }
}

enum RankDivision: Int {
    case I = 0, II, III, IV, V
    
    var title: String {
        switch self {
        case .I: return "I"
        case .II: return "II"
        case .III: return "III"
        case .IV: return "IV"
        case .V: return "V"
        }
    }
}

struct Rank {
    let title: String
    let textColor: Color
    let backgroundColor: Color
    let borderColor: Color
}



struct RankHelper {
    
    static func getRank(rating: Int) -> Rank {
        
        if rating > 9999 {
            let league = RankLeague.king
            
            return Rank(
                title: league.name,
                textColor: league.textColor,
                backgroundColor: league.backgroundColor,
                borderColor: league.borderColor
            )
        }
        
        let clamped = max(0, rating)
        
        let leagueIndex = clamped / 2000
        let league = RankLeague(rawValue: leagueIndex) ?? .ruby
        
        let divisionIndex = (clamped % 2000) / 400
        let division = RankDivision(rawValue: divisionIndex) ?? .I
        
        let title: String = "\(league.name) \(division.title)"
        
        
        return Rank(
            title: title,
            textColor: league.textColor,
            backgroundColor: league.backgroundColor,
            borderColor: league.borderColor
        )
    }
    
}
