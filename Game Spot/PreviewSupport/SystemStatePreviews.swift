#if DEBUG

import SwiftUI

#Preview("Privacy Policy") {
    NavigationStack {
        PrivacyPolicyView()
    }
}

#Preview("State · Error") {
    ContentStateView(
        title: "Couldn’t Load Games",
        message: "Check your connection and try again.",
        systemImage: "wifi.exclamationmark",
        accessibilityIdentifier: "preview.error",
        actionTitle: "Try Again"
    ) {}
}

#Preview("State · Empty") {
    ContentStateView(
        title: "No Games Yet",
        message: "Games you join or create will appear here.",
        systemImage: "sportscourt",
        accessibilityIdentifier: "preview.empty"
    )
}

#Preview("Loading · Branded") {
    LoadingView()
}

#Preview("Loading · Native") {
    NativeLoadingView(title: "Loading Profile")
}

#endif
