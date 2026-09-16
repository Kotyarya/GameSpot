import SwiftUI

struct ContentStateView: View {

    let title: String

    let message: String

    let systemImage: String

    let accessibilityIdentifier: String

    private let actionTitle: String?

    private let action: (() -> Void)?

    init(
        title: String,
        message: String,
        systemImage: String,
        accessibilityIdentifier: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {

        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.accessibilityIdentifier = accessibilityIdentifier
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {

        ContentUnavailableView {

            Label(
                title,
                systemImage: systemImage
            )

        } description: {

            Text(message)

        } actions: {

            if let actionTitle,
               let action {

                Button() {
                    action()
                } label : {
                        Text(actionTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(width: 250)
                            .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.glassProminent)
                .accessibilityIdentifier(
                    "\(accessibilityIdentifier).action"
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .accessibilityIdentifier(
            accessibilityIdentifier
        )
    }
}

#Preview("Error") {
    ContentStateView(
        title: "Couldn’t Load Games",
        message: "Check your connection and try again.",
        systemImage: "wifi.exclamationmark",
        accessibilityIdentifier: "preview.error",
        actionTitle: "Try Again",
        action: {}
    )
}

#Preview("Empty") {
    ContentStateView(
        title: "No Games Yet",
        message: "Explore a park and join your first game.",
        systemImage: "sportscourt",
        accessibilityIdentifier: "preview.empty"
    )
}
