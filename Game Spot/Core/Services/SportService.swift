import Foundation
import Supabase

final class SportService: @unchecked Sendable {
    static let shared = SportService()
    
    private let client = SupabaseService.shared.client
    
    private init() {}
    
    // MARK: - Fetch Sports
    func fetchSports() async throws -> [Sport] {
        try await client
            .from("sports")
            .select("*")
            .order("name", ascending: true)
            .execute()
            .value
    }
}
