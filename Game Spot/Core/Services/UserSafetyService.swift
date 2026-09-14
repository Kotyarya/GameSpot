import Foundation
import Supabase

// MARK: - Protocol

@MainActor
protocol UserSafetyServing:
    AnyObject,
    Sendable {

    func submitReport(
        userId: UUID,
        reason: ReportReason,
        details: String?
    ) async throws -> Bool

    func setBlocked(
        userId: UUID,
        isBlocked: Bool
    ) async throws

    func fetchBlockedUsers()
        async throws -> [BlockedUser]
}

// MARK: - Supabase Service

final class UserSafetyService:
    UserSafetyServing,
    @unchecked Sendable {

    static let shared =
        UserSafetyService()

    private let client =
        SupabaseService.shared.client

    private init() {}

    // MARK: Report

    func submitReport(
        userId: UUID,
        reason: ReportReason,
        details: String?
    ) async throws -> Bool {

        let trimmedDetails =
            details?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let params =
            SubmitReportParams(
                p_reported_user_id: userId,
                p_reason: reason.rawValue,
                p_details:
                    trimmedDetails?.isEmpty == true
                    ? nil
                    : trimmedDetails
            )

        return try await client
            .rpc(
                "submit_user_report",
                params: params
            )
            .execute()
            .value
    }

    // MARK: Block

    func setBlocked(
        userId: UUID,
        isBlocked: Bool
    ) async throws {

        let params =
            SetBlockParams(
                p_blocked_user_id: userId,
                p_is_blocked: isBlocked
            )

        try await client
            .rpc(
                "set_user_block",
                params: params
            )
            .execute()
    }

    // MARK: Blocked Users

    func fetchBlockedUsers()
        async throws -> [BlockedUser] {

        return try await client
            .from("user_blocks")
            .select(
                """
                blocked_id,
                blocked_username,
                blocked_avatar_url,
                created_at
                """
            )
            .order(
                "created_at",
                ascending: false
            )
            .execute()
            .value
    }
}

// MARK: - RPC Parameters

private extension UserSafetyService {

    struct SubmitReportParams:
        Encodable {

        let p_reported_user_id: UUID
        let p_reason: String
        let p_details: String?
    }

    struct SetBlockParams:
        Encodable {

        let p_blocked_user_id: UUID
        let p_is_blocked: Bool
    }
}
