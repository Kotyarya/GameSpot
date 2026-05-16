import SwiftUI

struct CreateGameView: View {
    
    // MARK: - Properties
    
    let park: Park
    
    let sports: [Sport]
    
    // MARK: - View Model
    
    @StateObject
    private var vm = CreateGameViewModel()
    
    // MARK: - Environment
    
    @EnvironmentObject
    private var router: AppRouter
    
    @Environment(\.dismiss)
    private var dismiss
    
    // MARK: - Computed Properties
    
    private var minimumDate: Date {
        
        Calendar.current.date(
            byAdding: .minute,
            value: 30,
            to: Date()
        ) ?? Date()
    }
    
    // MARK: - Body
    
    var body: some View {
        
        ZStack {
            
            backgroundView
            
            contentView
            
            if vm.isLoading {
                loadingOverlay
            }
        }
        .animation(
            .easeInOut(duration: 0.28),
            value: vm.isLoading
        )
        .navigationTitle("Create Game")
        .navigationBarTitleDisplayMode(.inline)
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
        
        ScrollView {
            
            VStack(spacing: 28) {
                
                headerSection
                
                sportSelectionSection
                
                dateSection
                
                if let sport = vm.selectedSport {
                    gameInfoSection(for: sport)
                }
                
                if let error = vm.errorMessage {
                    errorSection(error)
                }
                
                createButton
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .disabled(vm.isLoading)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        
        VStack(spacing: 14) {
            
            ZStack {
                
                Circle()
                    .fill(Color("AccentColor").opacity(0.12))
                    .frame(width: 104, height: 104)
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color("AccentColor"))
            }
            
            VStack(spacing: 4) {
                
                Text("Create Game")
                    .font(
                        .system(
                            size: 40,
                            weight: .bold
                        )
                    )
                
                Text(park.name)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 12)
    }
    
    // MARK: - Sport Selection Section
    
    private var sportSelectionSection: some View {
        
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            
            Text("Select Sport")
                .font(.title.bold())
            
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 16
            ) {
                
                ForEach(sports) { sport in
                    
                    sportCard(for: sport)
                }
            }
        }
    }
    
    private func sportCard(
        for sport: Sport
    ) -> some View {
        
        let isSelected =
            vm.selectedSport?.id == sport.id
        
        return Button {

            withAnimation(
                .spring(response: 0.3)
            ) {

                vm.selectedSport = sport
            }

        } label: {

            VStack(spacing: 14) {

                // MARK: - Icon

                ZStack {

                    Circle()
                        .fill(
                            isSelected
                            ? .white.opacity(0.15)
                            : Color("AccentColor").opacity(0.1)
                        )
                        .frame(width: 72, height: 72)

                    Image(
                        systemName:
                            sport.type?.iconName
                        ?? "sportscourt.fill"
                    )
                    .font(.system(size: 30))
                    .foregroundStyle(
                        isSelected
                        ? .white
                        : Color("AccentColor")
                    )
                }

                // MARK: - Text

                VStack(spacing: 6) {

                    Text(sport.name.capitalized)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            isSelected
                            ? .white
                            : .primary
                        )

                    Text(durationText(for: sport))
                        .font(.caption)
                        .foregroundStyle(
                            isSelected
                            ? .white.opacity(0.8)
                            : .secondary
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .glassEffect(
                .regular
                    .tint(
                        isSelected
                        ? Color("AccentColor").opacity(0.85)
                        : Color("inversePrimary").opacity(0.55)
                    )
                    .interactive(true),

                in: RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
            )
            .shadow(
                color: isSelected
                ? Color("AccentColor").opacity(0.25)
                : .black.opacity(0.05),

                radius: 16,
                y: 8
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Date Section
    
    private var dateSection: some View {
        
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            
            Text("Game Date")
                .font(.title.bold())
            
            VStack(spacing: 18) {
                
                HStack(spacing: 16) {
                    
                    ZStack {
                        
                        Circle()
                            .fill(Color("AccentColor").opacity(0.12))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundStyle(Color("AccentColor"))
                    }
                    
                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        
                        Text("Starts At")
                            .font(.headline)
                        
                        Text(
                            vm.startsAt.formatted(
                                date: .complete,
                                time: .shortened
                            )
                        )
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                DatePicker(
                    "",
                    selection: $vm.startsAt,
                    in: minimumDate...,
                    displayedComponents: [
                        .date,
                        .hourAndMinute
                    ]
                )
                .datePickerStyle(.graphical)
            }
            .padding(22)
            .glassEffect(
                .regular
                    .tint(Color("inversePrimary"))
                    .interactive(true),
                
                in: RoundedRectangle(
                    cornerRadius: 32,
                    style: .continuous
                )
            )
        }
    }
    
    // MARK: - Game Info Section
    
    private func gameInfoSection(
        for sport: Sport
    ) -> some View {
        
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            
            Text("Game Info")
                .font(.title.bold())
            
            HStack(spacing: 14) {
                
                infoCard(
                    icon: "clock.fill",
                    title: "Duration",
                    value: durationText(for: sport)
                )
                
                infoCard(
                    icon: "person.3.fill",
                    title: "Players",
                    value: maxPlayersText(for: sport)
                )
                
                infoCard(
                    icon:
                        sport.type?.iconName
                    ?? "sportscourt.fill",
                    
                    title: "Sport",
                    value: sport.name.capitalized
                )
            }
        }
    }
    
    // MARK: - Error Section
    
    private func errorSection(
        _ error: String
    ) -> some View {
        
        HStack(spacing: 12) {
            
            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .foregroundStyle(.orange)
            .font(.title3)
            
            Text(error)
                .fontWeight(.semibold)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(.orange.opacity(0.12))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        
        Button {
            
            createGame()
            
        } label: {
            
            HStack(spacing: 12) {
                
                Image(
                    systemName:
                        "plus.circle.fill"
                )
                .font(.title3)
                
                Text("Create Game")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color("AccentColor"))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 26
                )
            )
            .shadow(
                color: Color("AccentColor").opacity(0.35),
                radius: 18,
                y: 8
            )
        }
        .disabled(
            vm.selectedSport == nil
            || vm.isLoading
        )
        .opacity(
            vm.selectedSport == nil
            ? 0.5
            : 1
        )
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        
        ZStack {
            
            Rectangle()
                .fill(.black.opacity(0.12))
                .ignoresSafeArea()
            
            LoadingView()
                .transition(
                    .opacity.combined(
                        with: .scale(scale: 0.96)
                    )
                )
        }
        .zIndex(999)
    }
    
    // MARK: - Components
    
    private func infoCard(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        
        VStack(spacing: 10) {
            
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color("AccentColor"))
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .glassEffect(
            .regular
                .tint(Color("inversePrimary"))
                .interactive(true),
            
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
    
    // MARK: - Actions
    
    private func createGame() {
        
        Task {
            
            if let gameId = await vm.createGame(
                parkId: park.id
            ) {
                
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.success)
                
                dismiss()
                
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.15
                ) {
                    
                    router.push(.game(gameId))
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func durationText(
        for sport: Sport
    ) -> String {
        
        switch sport.name.lowercased() {
            
        case "volleyball":
            return "50 min"
            
        case "football":
            return "110 min"
            
        case "basketball":
            return "60 min"
            
        default:
            return "60 min"
        }
    }
    
    private func maxPlayersText(
        for sport: Sport
    ) -> String {
        
        switch sport.name.lowercased() {
            
        case "volleyball":
            return "12 Players"
            
        case "football":
            return "22 Players"
            
        case "basketball":
            return "10 Players"
            
        default:
            return "10 Players"
        }
    }
}
