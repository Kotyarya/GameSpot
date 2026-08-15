import Foundation

enum AppConfiguration {

    static let supabaseURL = requiredURL(
        forKey: "SupabaseURL"
    )

    static let supabasePublishableKey = requiredString(
        forKey: "SupabasePublishableKey"
    )

    private static func requiredURL(
        forKey key: String
    ) -> URL {

        let value = requiredString(forKey: key)

        guard
            let url = URL(string: value),
            let scheme = url.scheme,
            ["http", "https"].contains(scheme),
            url.host != nil
        else {
            preconditionFailure(
                "Invalid \(key) in the app configuration."
            )
        }

        return url
    }

    private static func requiredString(
        forKey key: String
    ) -> String {

        guard
            let value = Bundle.main.object(
                forInfoDictionaryKey: key
            ) as? String,
            !value.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        else {
            preconditionFailure(
                "Missing \(key) in the app configuration."
            )
        }

        return value
    }
}
