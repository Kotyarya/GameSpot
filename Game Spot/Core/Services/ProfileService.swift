import Foundation
import Supabase

final class ProfileService: @unchecked Sendable {

    // MARK: - Shared

    static let shared = ProfileService()

    // MARK: - Properties

    private let client = SupabaseService.shared.client

    // MARK: - Profile

    func fetchProfile(
        userId: UUID
    ) async throws -> Profile {

        return try await client
            .from("profiles")
            .select(
                """
                id,
                username,
                avatar_url,
                favorite_sport_id,
                sports!favorite_sport_id (
                    id,
                    name
                ),
                rating,
                games_played,
                mvp_count,
                perf_points,
                is_onboarded,
                is_profile_completed,
                created_at,
                updated_at
                """
            )
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    // MARK: - Stats

    func fetchUserStats(
        userId: UUID
    ) async throws -> [UserSportStats] {

        return try await client
            .from("user_sport_stats")
            .select(
                """
                id,
                user_id,
                sport_id,
                rating,
                games_played,
                mvp_count,
                perf_points,
                sports (
                    id,
                    name
                )
                """
            )
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    // MARK: - Recent Matches

    func getRecentMatches() async throws -> [RecentMatch] {

        return try await client
            .rpc("get_recent_matches")
            .execute()
            .value
    }

    // MARK: - Username

    func isUsernameAvailable(
        _ username: String
    ) async throws -> Bool {

        let users: [IdOnly] = try await client
            .from("profiles")
            .select("id")
            .eq("username", value: username)
            .execute()
            .value

        return users.isEmpty
    }

    // MARK: - Onboarding

    func markOnboardingComplete(
        userId: UUID
    ) async throws {

        try await client
            .from("profiles")
            .update([
                "is_onboarded": true
            ])
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Complete Profile

    func completeProfile(
        userId: UUID,
        username: String,
        avatarUrl: String?,
        sportId: UUID
    ) async throws {

        let payload = CompleteProfilePayload(
            username: username,
            avatar_url: avatarUrl,
            favorite_sport_id: sportId.uuidString,
            is_profile_completed: true
        )

        try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: userId)
            .execute()
    }
}

// MARK: - DTOs

private extension ProfileService {

    struct IdOnly: Decodable {

        let id: UUID
    }

    struct CompleteProfilePayload: Encodable {

        let username: String

        let avatar_url: String?

        let favorite_sport_id: String

        let is_profile_completed: Bool
    }
}
