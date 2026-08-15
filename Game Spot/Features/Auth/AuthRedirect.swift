import Foundation

enum AuthLinkRoute: Equatable {

    case emailConfirmation
    case passwordRecovery
}

enum AuthRedirect {

    static let emailConfirmation = URL(
        string: "gamespot://auth/confirmed"
    )!

    static let passwordRecovery = URL(
        string: "gamespot://auth/recovery"
    )!

    static func route(
        for url: URL
    ) -> AuthLinkRoute? {

        guard url.scheme?.lowercased() == "gamespot",
              url.host?.lowercased() == "auth" else {
            return nil
        }

        switch url.path.lowercased() {
        case "/confirmed":
            return .emailConfirmation
        case "/recovery":
            return .passwordRecovery
        default:
            return nil
        }
    }
}
