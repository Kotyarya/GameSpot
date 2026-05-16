import Foundation
import Supabase

final class ParkService: @unchecked Sendable {

    // MARK: - Shared

    static let shared = ParkService()

    // MARK: - Properties

    private let client = SupabaseService.shared.client

    // MARK: - Parks

    func fetchParks() async throws -> [Park] {

        return try await client
            .from("parks")
            .select("*")
            .eq("is_active", value: true)
            .execute()
            .value
    }

    func fetchPark(
        parkId: UUID
    ) async throws -> Park {

        return try await client
            .from("parks")
            .select("""
                id,
                name,
                latitude,
                longitude,
                address,
                is_active,
                has_lighting
            """)
            .eq("id", value: parkId.uuidString)
            .single()
            .execute()
            .value
    }

    func fetchParkDetails(
        parkId: UUID
    ) async throws -> ParkDetails {

        async let parkTask =
            fetchPark(parkId: parkId)

        async let sportsTask =
            fetchSports(parkId: parkId)

        async let hoursTask =
            fetchHours(parkId: parkId)

        async let imagesTask =
            fetchImages(parkId: parkId)

        async let ratingTask =
            fetchRating(parkId: parkId)

        let park = try await parkTask
        let sports = try await sportsTask
        let hours = try await hoursTask
        let images = try await imagesTask
        let rating = try await ratingTask

        return ParkDetails(
            park: park,
            sports: sports,
            hours: hours,
            images: images,
            rating: rating
        )
    }

    // MARK: - Hours

    func fetchHours(
        parkId: UUID
    ) async throws -> [ParkHour] {

        return try await client
            .from("parks_hour")
            .select("""
                id,
                day_of_week,
                open_hour,
                close_time,
                is_closed
            """)
            .eq("park_id", value: parkId.uuidString)
            .order(
                "day_of_week",
                ascending: true
            )
            .execute()
            .value
    }

    // MARK: - Images

    func fetchImages(
        parkId: UUID
    ) async throws -> [ParkImage] {

        return try await client
            .from("parks_images")
            .select("""
                id,
                image_url,
                is_main
            """)
            .eq("park_id", value: parkId.uuidString)
            .order(
                "is_main",
                ascending: false
            )
            .execute()
            .value
    }

    // MARK: - Sports

    func fetchSports(
        parkId: UUID
    ) async throws -> [Sport] {

        let response: [ParkSportResponse] =
            try await client
                .from("parks_sports")
                .select("""
                    sports (
                        id,
                        name
                    )
                """)
                .eq(
                    "park_id",
                    value: parkId.uuidString
                )
                .execute()
                .value

        return response.map(\.sports)
    }

    // MARK: - Ratings

    func fetchRating(
        parkId: UUID
    ) async throws -> ParkRating {

        return try await client
            .from("parks_ratings")
            .select("""
                quality_avg,
                quality_count,
                facilities_avg,
                facilities_count,
                activity_avg,
                activity_count,
                overall_avg
            """)
            .eq("park_id", value: parkId.uuidString)
            .single()
            .execute()
            .value
    }

    func ratePark(
        userId: UUID,
        parkId: UUID,
        quality: Int,
        facilities: Int,
        activity: Int
    ) async throws {

        let params = RateParkParams(
            p_user_id: userId,
            p_park_id: parkId,
            p_quality: quality,
            p_facilities: facilities,
            p_activity: activity
        )

        try await client
            .rpc(
                "rate_park",
                params: params
            )
            .execute()
    }

    func hasUserRated(
        userId: UUID,
        parkId: UUID
    ) async throws -> Bool {

        let params = HasRatedParams(
            p_user_id: userId,
            p_park_id: parkId
        )

        return try await client
            .rpc(
                "has_user_rated",
                params: params
            )
            .execute()
            .value
    }
}

// MARK: - DTOs

private extension ParkService {

    struct RateParkParams: Encodable {

        let p_user_id: UUID
        let p_park_id: UUID
        let p_quality: Int
        let p_facilities: Int
        let p_activity: Int
    }

    struct HasRatedParams: Encodable {

        let p_user_id: UUID
        let p_park_id: UUID
    }

    struct ParkSportResponse: Decodable {

        let sports: Sport
    }
}
