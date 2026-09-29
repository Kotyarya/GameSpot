#if DEBUG

import SwiftUI

#Preview("Main Tabs") {
    MainTabView(
        mapViewModel: PreviewFactory.map(),
        parkViewModel: PreviewFactory.parkDetails(),
        gamesViewModel: PreviewFactory.games(),
        profileViewModel: PreviewFactory.profile()
    )
    .environmentObject(AppRouter())
    .environmentObject(PreviewFactory.session())
}

#endif
