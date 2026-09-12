import Foundation
import SwiftUI
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

    @Published private(set) var isLoadingSports = false

    @Published private(set) var didAttemptSportsLoad = false

    @Published private(set) var sportsErrorMessage: String?

    @Published var isUsernameAvailable:
        Bool? = nil

    // MARK: - Tasks

    private var usernameTask:
        Task<Void, Never>?

    private var uploadedAvatarInCurrentSetup = false

    // MARK: - Dependencies

    private let profileService: any ProfileSetupServing

    private let sportService: any SportFetching

    private let avatarStorage: any AvatarStoring

    private let minimumLoadingDuration: TimeInterval

    // MARK: - Init

    init(
        profileService: any ProfileSetupServing = ProfileService.shared,
        sportService: any SportFetching = SportService.shared,
        avatarStorage: any AvatarStoring = SupabaseAvatarStorageService.shared,
        minimumLoadingDuration: TimeInterval = 2
    ) {

        self.profileService = profileService
        self.sportService = sportService
        self.avatarStorage = avatarStorage
        self.minimumLoadingDuration = minimumLoadingDuration
    }

    // MARK: - Load Sports

    func loadSports() async {

        guard !isLoadingSports else {
            return
        }

        didAttemptSportsLoad = true

        isLoadingSports = true

        sportsErrorMessage = nil

        defer {
            isLoadingSports = false
        }

        do {

            sports =
                try await sportService
                    .fetchSports()

        } catch {

            if error is CancellationError {
                return
            }

            sportsErrorMessage =
                "Couldn’t load sports. Check your connection and try again."

            AppLogger.error(
                "Profile setup sports load failed",
                error: error
            )
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

        guard let image = avatarImage else {

            return nil
        }

        let url = try await avatarStorage
            .uploadAvatar(
                image,
                userId: userId
            )

        uploadedAvatarInCurrentSetup = true
        return url.absoluteString
    }

    // MARK: - Submit

    func submit(
        userId: UUID
    ) async throws {

        guard !isLoading else {
            throw ProfileSetupSubmissionError.alreadyInProgress
        }

        let startTime = Date()

        errorMessage = nil

        do {
            try validateInput()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }

        withAnimation(
            .easeInOut(duration: 0.2)
        ) {

            isLoading = true
        }

        do {

            let avatarUrl: String?

            if avatarImage == nil,
               uploadedAvatarInCurrentSetup {

                try await avatarStorage.removeAvatar(userId: userId)
                uploadedAvatarInCurrentSetup = false
                avatarUrl = nil

            } else {

                avatarUrl = try await uploadAvatar(
                    userId: userId
                )
            }

            try await profileService
                .completeProfile(
                    userId: userId,
                    username: username,
                    avatarUrl: avatarUrl,
                    sportId: selectedSport!.id
                )

            await finishLoading(
                startTime: startTime
            )

        } catch {

            errorMessage =
                userFacingMessage(for: error)

            AppLogger.error(
                "Profile setup failed",
                error: error
            )

            await finishLoading(
                startTime: startTime
            )

            throw error
        }
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

        if elapsed < minimumLoadingDuration {

            let remaining =
                minimumLoadingDuration - elapsed

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

    private func userFacingMessage(
        for error: Error
    ) -> String {

        if let encodingError = error as? AvatarImageEncodingError {
            return encodingError.localizedDescription
        }

        return "Couldn’t save your profile. Please try again."
    }
}

private enum ProfileSetupSubmissionError: LocalizedError {

    case alreadyInProgress

    var errorDescription: String? {
        "Your profile is already being saved."
    }
}
