import Foundation
import Supabase


final class SupabaseService: @unchecked Sendable{
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init () {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://xoopxlnqyxfqurroogrz.supabase.co")!,
            supabaseKey: "sb_publishable_n7dawFU2aQMpyDUyzcYMWA_XgG4mDso"
        )
    }
}
