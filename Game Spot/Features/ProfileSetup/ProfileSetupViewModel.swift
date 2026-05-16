import Foundation
import SwiftUI
import Supabase
import Combine

@MainActor
final class ProfileSetupViewModel:
    ObservableObject {

    // MARK: - Inputs

    @Published var username: String = "" {

        didSet {
            debounceUsernameCheck()
        }
    }

    @Published var selectedSport: Sport?

    @Published var avatarImage: UIImage?

    // MARK: - State

    @Published var sports: [Sport] = []

    @Published var isLoading = false

    @Published var errorMessage: String?

    @Published var isUsernameAvailable:
        Bool? = nil

    // MARK: - Tasks

    private var usernameTask:
        Task<Void, Never>?

    // MARK: - Dependencies

    private let profileService =
        ProfileService.shared

    private let sportService =
        SportService.shared

    private let client =
        SupabaseService.shared.client

    // MARK: - Load Sports

    func loadSports() async {

        do {

            sports =
                try await sportService
                    .fetchSports()

        } catch {

            errorMessage =
                "Failed to load sports"
        }
    }

    // MARK: - Username Validation

    private func debounceUsernameCheck() {

        usernameTask?.cancel()

        guard username.count >= 3 else {

            isUsernameAvailable = nil

            return
        }

        usernameTask = Task {

            try? await Task.sleep(
                nanoseconds: 400_000_000
            )

            await checkUsername()
        }
    }

    private func checkUsername() async {

        do {

            let available =
                try await profileService
                    .isUsernameAvailable(
                        username
                    )

            print(available)

            isUsernameAvailable =
                available

        } catch {

            isUsernameAvailable = nil
        }
    }

    // MARK: - Avatar Upload

    func uploadAvatar(
        userId: UUID
    ) async throws -> String? {

        guard let image = avatarImage,
              let data = image.jpegData(
                compressionQuality: 0.8
              ) else {

            return nil
        }

        let path =
            "\(userId)/avatar.jpg"

        print("UPLOAD PATH:", path)

        try await client.storage
            .from("avatars")
            .upload(
                path,
                data: data,
                options: FileOptions(
                    contentType: "image/jpeg"
                )
            )

        let url = try client.storage
            .from("avatars")
            .getPublicURL(
                path: path
            )

        return url.absoluteString
    }

    // MARK: - Submit

    func submit(
        userId: UUID
    ) async throws {

        let startTime = Date()

        try validateInput()

        withAnimation(
            .easeInOut(duration: 0.2)
        ) {

            isLoading = true
        }

        do {

            let avatarUrl =
                try await uploadAvatar(
                    userId: userId
                )

            try await profileService
                .completeProfile(
                    userId: userId,
                    username: username,
                    avatarUrl: avatarUrl,
                    sportId: selectedSport!.id
                )

        } catch {

            errorMessage =
                error.localizedDescription
        }

        await finishLoading(
            startTime: startTime
        )
    }

    // MARK: - Validation

    private func validateInput() throws {

        guard let isAvailable =
                isUsernameAvailable,
              isAvailable else {

            throw NSError(
                domain: "",
                code: 0,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Username not available"
                ]
            )
        }

        guard selectedSport != nil else {

            throw NSError(
                domain: "",
                code: 0,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Select sport"
                ]
            )
        }
    }

    // MARK: - Loading

    private func finishLoading(
        startTime: Date
    ) async {

        let elapsed =
            Date().timeIntervalSince(
                startTime
            )

        let minimumDuration = 2.0

        if elapsed < minimumDuration {

            let remaining =
                minimumDuration - elapsed

            try? await Task.sleep(
                for: .seconds(remaining)
            )
        }

        withAnimation(
            .easeInOut(duration: 0.25)
        ) {

            isLoading = false
        }
    }
}
