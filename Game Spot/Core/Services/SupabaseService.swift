import Supabase

final class SupabaseService: @unchecked Sendable {

    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: AppConfiguration.supabaseURL,
            supabaseKey: AppConfiguration.supabasePublishableKey,
            options: SupabaseClientOptions(
                auth: .init(
                    redirectToURL: AuthRedirect.emailConfirmation,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
}
