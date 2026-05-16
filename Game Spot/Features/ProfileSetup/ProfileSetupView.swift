import SwiftUI
import PhotosUI
internal import Auth

struct ProfileSetupView: View {

    // MARK: - View Model

    @StateObject private var viewModel =
        ProfileSetupViewModel()

    // MARK: - Environment

    @EnvironmentObject var session:
        SessionManager

    // MARK: - State

    @State private var selectedItem:
        PhotosPickerItem?

    @FocusState private var usernameFocused:
        Bool

    // MARK: - Constants

    private let primary = Color("AccentColor")

    // MARK: - Body

    var body: some View {

        ZStack {

            backgroundView

            contentView
        }
        .task {
            await viewModel.loadSports()
        }
        .overlay {

            if viewModel.isLoading {

                LoadingView()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
        .animation(
            .easeInOut(duration: 0.25),
            value: viewModel.isLoading
        )
    }

    // MARK: - Background

    private var backgroundView: some View {

        LinearGradient(
            colors: [
                Color("AccentColor").opacity(0.3),
                Color("inversePrimary")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Content

    private var contentView: some View {

        ScrollView(showsIndicators: false) {

            VStack(spacing: 30) {

                Spacer(minLength: 24)

                headerSection

                mainCardSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Header

    private var headerSection: some View {

        VStack(spacing: 14) {

            Text("Complete Your Profile")
                .font(
                    .system(
                        size: 38,
                        weight: .bold
                    )
                )
                .fontDesign(.rounded)
                .multilineTextAlignment(.center)

            Text(
                """
                Choose your avatar, nickname and favorite sport.
                """
            )
            .font(.headline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    // MARK: - Main Card

    private var mainCardSection: some View {

        VStack(spacing: 28) {

            avatarSection

            usernameSection

            favoriteSportSection

            errorSection

            continueButton
        }
        .padding(24)
        .glassEffect(
            .regular
                .tint(
                    Color("inversePrimary")
                )
                .interactive(true),

            in: RoundedRectangle(
                cornerRadius: 34,
                style: .continuous
            )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 20,
            y: 12
        )
    }

    // MARK: - Avatar

    private var avatarSection: some View {

        VStack(spacing: 16) {

            let avatarImage = viewModel.avatarImage

            PhotosPicker(
                selection: $selectedItem,
                matching: .images
            ) {

                ZStack {

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    primary.opacity(0.18),
                                    primary.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: 132,
                            height: 132
                        )

                    if let image = avatarImage {

                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: 132,
                                height: 132
                            )
                            .clipShape(Circle())

                    } else {

                        VStack(spacing: 8) {

                            Image(systemName: "camera.fill")
                                .font(.system(size: 34))

                            Text("Add Photo")
                                .font(.headline)
                        }
                        .foregroundStyle(primary)
                    }
                }
                .overlay {

                    Circle()
                        .stroke(
                            .white.opacity(0.8),
                            lineWidth: 3
                        )
                }
                .shadow(
                    color: primary.opacity(0.25),
                    radius: 16,
                    y: 10
                )
            }
            .onChange(of: selectedItem) { _, newItem in

                Task {

                    if let data = try? await newItem?
                        .loadTransferable(type: Data.self),

                       let uiImage = UIImage(data: data) {

                        await MainActor.run {
                            viewModel.avatarImage = uiImage
                        }
                    }
                }
            }
        }
    }

    

    // MARK: - Avatar Placeholder

    private var avatarPlaceholder: some View {

        VStack(spacing: 8) {

            Image(systemName: "camera.fill")
                .font(.system(size: 34))

            Text("Add Photo")
                .font(.headline)
        }
        .foregroundStyle(primary)
    }

    // MARK: - Username

    private var usernameSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Username")
                .font(.headline)

            usernameField

            usernameAvailabilityView
        }
    }

    // MARK: - Username Field

    private var usernameField: some View {

        HStack(spacing: 12) {

            Image(systemName: "person.fill")
                .foregroundStyle(primary)

            TextField(
                "Enter username",
                text: $viewModel.username
            )
            .focused($usernameFocused)
            .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 16)
        .frame(height: 58)
        .background(Color("inversePrimary"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    // MARK: - Username Availability

    @ViewBuilder
    private var usernameAvailabilityView:
        some View {

        if let available =
            viewModel.isUsernameAvailable {

            HStack(spacing: 8) {

                Image(
                    systemName:
                        available
                    ? "checkmark.circle.fill"
                    : "xmark.circle.fill"
                )
                .foregroundStyle(
                    available
                    ? .green
                    : .red
                )

                Text(
                    available
                    ? "Username available"
                    : "Username already taken"
                )
                .font(.subheadline)
                .foregroundStyle(
                    available
                    ? .green
                    : .red
                )
            }
        }
    }

    // MARK: - Favorite Sport

    private var favoriteSportSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Favorite Sport")
                    .font(.headline)

                Text(
                    """
                    This will customize your profile style.
                    """
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            sportsGrid
        }
    }

    // MARK: - Sports Grid

    private var sportsGrid: some View {

        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 82))
            ],
            spacing: 18
        ) {

            ForEach(viewModel.sports) { sport in

                sportButton(for: sport)
            }
        }
    }

    // MARK: - Sport Button

    private func sportButton(
        for sport: Sport
    ) -> some View {

        let isSelected =
            viewModel.selectedSport?.id
            == sport.id

        return Button {

            withAnimation(.spring) {
                viewModel.selectedSport = sport
            }

        } label: {

            VStack(spacing: 10) {

                SportGlassPin(
                    sport: sport,
                    tint:
                        isSelected
                    ? Color("AccentColor")
                    : .gray.opacity(0.3)
                )
                .scaleEffect(
                    isSelected
                    ? 1.08
                    : 1
                )

                Text(
                    sport.name.capitalized
                )
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(
                    isSelected
                    ? .primary
                    : .secondary
                )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error

    @ViewBuilder
    private var errorSection: some View {

        if let error =
            viewModel.errorMessage {

            HStack(spacing: 10) {

                Image(
                    systemName:
                        "exclamationmark.circle.fill"
                )

                Text(error)
                    .font(.subheadline)
            }
            .foregroundStyle(.red)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {

        Button {

            Task {

                guard let userId =
                    session.user?.id else {
                    return
                }

                try? await viewModel.submit(
                    userId: userId
                )

                await session.loadProfile()
            }

        } label: {

            ZStack {

                Text("Continue")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .buttonStyle(.glassProminent)
        .tint(Color("AccentColor"))
        .disabled(
            viewModel.isLoading
            || viewModel.isUsernameAvailable != true
            || viewModel.selectedSport == nil
        )
        .opacity(
            (
                viewModel.isUsernameAvailable == true
                && viewModel.selectedSport != nil
            )
            ? 1
            : 0.6
        )
    }
}

#Preview {
    ProfileSetupView()
}
