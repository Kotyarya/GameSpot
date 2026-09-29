import Foundation
import Supabase
import UIKit

@MainActor
protocol AvatarStoring: AnyObject {

    func uploadAvatar(
        _ image: UIImage,
        userId: UUID
    ) async throws -> URL

    func removeAvatar(
        userId: UUID
    ) async throws
}

@MainActor
final class SupabaseAvatarStorageService: AvatarStoring {

    static let shared = SupabaseAvatarStorageService()

    private let client = SupabaseService.shared.client

    private init() {}

    func uploadAvatar(
        _ image: UIImage,
        userId: UUID
    ) async throws -> URL {

        let data = try AvatarImageEncoder.jpegData(from: image)
        let path = avatarPath(for: userId)
        let bucket = client.storage.from("avatars")

        try await bucket.upload(
            path,
            data: data,
            options: FileOptions(
                cacheControl: "3600",
                contentType: "image/jpeg",
                upsert: true
            )
        )

        let publicURL = try bucket.getPublicURL(path: path)
        return cacheBustedURL(publicURL)
    }

    func removeAvatar(
        userId: UUID
    ) async throws {

        try await client.storage
            .from("avatars")
            .remove(paths: [avatarPath(for: userId)])
    }

    private func avatarPath(
        for userId: UUID
    ) -> String {

        "\(userId.uuidString.lowercased())/avatar.jpg"
    }

    private func cacheBustedURL(
        _ url: URL
    ) -> URL {

        guard var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            return url
        }

        components.queryItems = [
            URLQueryItem(
                name: "v",
                value: UUID().uuidString.lowercased()
            )
        ]

        return components.url ?? url
    }
}
