func formatTime(_ time: String?) -> String {
    guard let time else { return "--:--" }
    
    let components = time.split(separator: ":")
    
    if components.count >= 2 {
        return "\(components[0]):\(components[1])"
    }
    
    return "--:--"
}
