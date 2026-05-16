import Foundation

struct NumberFormatterHelper {
    
    static func formatRating(
        _ value: Int
    ) -> String {
        
        let absValue = Double(abs(value))
        
        let sign = value < 0 ? "-" : ""
        
        switch absValue {
            
        case 1_000_000_000...:
            
            let formatted = absValue / 1_000_000_000
            
            return "\(sign)\(format(formatted))B"
            
        case 1_000_000...:
            
            let formatted = absValue / 1_000_000
            
            return "\(sign)\(format(formatted))M"
            
        case 1_000...:
            
            let formatted = absValue / 1_000
            
            return "\(sign)\(format(formatted))K"
            
        default:
            
            return "\(value)"
        }
    }
    
    private static func format(
        _ number: Double
    ) -> String {

        let formatted: String

        if number >= 100 {
            formatted = String(format: "%.0f", number)
        } else {
            formatted = String(format: "%.1f", number)
        }

        return formatted.replacingOccurrences(
            of: ".0",
            with: ""
        )
    }
}
