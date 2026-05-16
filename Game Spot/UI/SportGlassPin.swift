import SwiftUI


struct SportGlassPin: View {
    let sport: Sport
    let tint: Color
    
    var body: some View {
        ZStack {
            Image(systemName: sport.type?.iconName ?? "")
                .font(.largeTitle)
                .foregroundStyle(.white)
        }
        .frame(width: 64, height: 64)
        .glassEffect(.regular.tint(tint).interactive(true), in: .circle)
    }
}
