import SwiftUI
import MapKit
internal import Auth

struct GameInfoView: View {
    
    @StateObject private var vm: GameInfoViewModel = GameInfoViewModel()
    
    @State private var selectedItem: MKMapItem?
    
    @State private var showJoinSheet = false
    @EnvironmentObject var session: SessionManager
    @State private var livePulse = false
    
    let gameId: UUID
    
    @State private var showMVPInfo = false
    
    // MARK: - Helpers
    
    private var details: GameDetails? {
        vm.details
    }
    
    private var isActuallyLive: Bool {

        guard let details else {
            return false
        }

        guard !details.isFinished else {
            return false
        }

        let endDate =
            details.startsAt.addingTimeInterval(
                Double(details.durationMinutes * 60)
            )

        return Date() >= details.startsAt
            && Date() <= endDate
    }
    
    private var sportIcon: String {
        details?.sport.type?.iconName ?? "sportscourt.fill"
    }
    
    private var gameStatus: String {

        guard let details else {
            return "Open"
        }

        if details.isFinished {
            return "Finished"
        }

        if isActuallyLive {
            return "Live"
        }

        if details.joinedPlayers >= details.maxPlayers {
            return "Full"
        }

        return "Open"
    }
    
    private var isOpen: Bool {

        guard let details else {
            return false
        }

        return
               !details.isFinished
               && !isActuallyLive
               && details.joinedPlayers < details.maxPlayers
    }
    
    private var isJoined: Bool {

        guard let userId = session.user?.id else {
            return false
        }

        return details?.players.contains {
            $0.id == userId
        } ?? false
    }
    
    private var parkItem: MKMapItem? {
        guard let park = details?.park else { return nil }
        
        let item = MKMapItem(
            location: CLLocation(
                latitude: park.latitude,
                longitude: park.longitude
            ),
            address: nil
        )
        
        item.name = park.name
        
        return item
    }
    
    private var region: MKCoordinateRegion {
        guard let park = details?.park else {
            return MKCoordinateRegion()
        }
        
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: park.latitude,
                longitude: park.longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.01,
                longitudeDelta: 0.01
            )
        )
    }
    
    private var shouldShowCountdown: Bool {

        guard let details else {
            return false
        }

        if isActuallyLive {
            return true
        }

        let diff = details.startsAt.timeIntervalSince(Date())

        return diff > 0 && diff <= 86400
    }
    
    private func countdownText(
        from now: Date
    ) -> String {

        guard let startsAt = details?.startsAt else {
            return "--:--:--"
        }

        let totalSeconds = Int(
            startsAt.timeIntervalSince(now)
        )

        if totalSeconds <= 0 {
            return "00:00:00"
        }

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return String(
            format: "%02d:%02d:%02d",
            hours,
            minutes,
            seconds
        )
    }
    
    private func formattedTime() -> String {
        guard let date = details?.startsAt else {
            return "--:--"
        }
        
        return date.formatted(
            .dateTime
                .hour()
                .minute()
        )
    }
    
    private func formattedDate() -> String {
        guard let date = details?.startsAt else {
            return "-"
        }
        
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        }
        
        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        
        return date.formatted(
            .dateTime
                .month()
                .day()
        )
    }
    
    private var teamAlpha: [Player] {
        details?.players.filter {
            $0.team == .alpha
        } ?? []
    }

    private var teamBeta: [Player] {
        details?.players.filter {
            $0.team == .beta
        } ?? []
    }
    
    @ViewBuilder
    private func avatarView(_ player: Player) -> some View {
        
        if let avatarUrl = player.avatarUrl,
           let url = URL(string: avatarUrl) {
            
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                placeholderAvatar
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            
        } else {
            
            placeholderAvatar
        }
    }
    
    private var placeholderAvatar: some View {
        Image(systemName: "person.fill")
            .font(.system(size: 22))
            .foregroundStyle(Color("AccentColor"))
            .frame(width: 52, height: 52)
            .background {
                Circle()
                    .fill(Color("inversePrimary"))
            }
            .overlay {
                Circle()
                    .stroke(Color("AccentColor"), lineWidth: 3)
            }
    }
    
    private var topRatedPlayer: Player? {
        details?.players.first(where: { $0.isTopRated })
    }

    private var mostActivePlayer: Player? {
        details?.players.first(where: { $0.isMostActive })
    }

    private var newestPlayer: Player? {
        details?.players.first(where: { $0.isNewest })
    }
    
    private func highlightPlayer(
        player: Player?,
        title: String,
        icon: String,
        iconColor: Color
    ) -> some View {
        
        VStack(spacing: 6) {
            
            ZStack(alignment: .topTrailing) {
                
                if let avatar = player?.avatarUrl,
                   let url = URL(string: avatar) {
                    
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        placeholderAvatar
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    
                } else {
                    
                    placeholderAvatar
                        .frame(width: 64, height: 64)
                }
                
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(iconColor)
                    .offset(x: 16, y: -16)
            }
            
            Text(player?.username ?? "No user")
                .font(.system(size: 17, weight: .bold))
            
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
        }
    }
    
    
    var body: some View {

        Group {
        
            if vm.isLoading && vm.details == nil {
                
                LoadingView()
                
            } else if let details {
                
                ZStack(alignment: .bottom) {
                    
                    ScrollView {
                        
                        // MARK: HEADER
                        
                        ZStack {
                            
                            Image(systemName: sportIcon)
                                .font(.system(size: 256))
                                .foregroundStyle(Color("AccentColor"))
                            
                            VStack(spacing: 4) {
                                
                                Text(details.sport.name.capitalized)
                                    .font(.system(size: 42))
                                    .bold()
                                    .foregroundStyle(
                                        Color(
                                            red: 42 / 255,
                                            green: 32 / 255,
                                            blue: 148 / 255
                                        )
                                    )
                                
                                Text(formattedTime())
                                    .font(.largeTitle)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        Color(
                                            red: 42 / 255,
                                            green: 32 / 255,
                                            blue: 148 / 255
                                        )
                                    )
                                
                                HStack {
                                    Image(systemName: "calendar")
                                    
                                    Text(formattedDate())
                                        .bold()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color("AccentColor"))
                                .foregroundStyle(.white)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 8)
                                )
                                
                                HStack(spacing: 8) {
                                    
                                    Image(systemName: "map.fill")
                                    
                                    Text(details.park.name)
                                        .bold()
                                    
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 8))
                                    
                                    Text(gameStatus)
                                        .bold()
                                }
                                .padding(.top, 8)
                                .foregroundStyle(
                                    Color(
                                        red: 42 / 255,
                                        green: 32 / 255,
                                        blue: 148 / 255
                                    )
                                )
                            }
                            .padding(.bottom, 8)
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .bottom
                            )
                            .background(
                                LinearGradient(
                                    stops: [
                                        .init(
                                            color: Color("lightPrimary"),
                                            location: 0.35
                                        ),
                                        .init(
                                            color: Color("lightPrimary").opacity(0),
                                            location: 1.0
                                        )
                                    ],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                        }
                        .padding(.bottom, 20)
                        .frame(height: 435)
                        .background(Color("lightPrimary"))
                        .clipShape(
                            RoundedRectangle(cornerRadius: 48)
                        )
                        
                        VStack(spacing: 32) {
                            
                            // MARK: COUNTDOWN
                            
                            if shouldShowCountdown {

                                VStack(alignment: .leading) {

                                    Text(
                                        details.isInProgress
                                        ? "Game in Progress"
                                        : "Game Starts in"
                                    )
                                    .font(.largeTitle)
                                    .bold()

                                    VStack {

                                        if isActuallyLive {

                                            VStack(spacing: 18) {

                                                ZStack {

                                                    Circle()
                                                        .fill(.red)
                                                        .frame(width: 22, height: 22)
                                                        .scaleEffect(livePulse ? 0.7 : 1)
                                                        .opacity(livePulse ? 0.35 : 1)
                                                        .animation(
                                                            .easeInOut(duration: 1)
                                                                .repeatForever(),
                                                            value: livePulse
                                                        )

                                                    Circle()
                                                        .fill(.red)
                                                        .frame(width: 12, height: 12)
                                                }

                                                Text("LIVE")
                                                    .font(.system(size: 56))
                                                    .bold()
                                                    .fontDesign(.rounded)
                                                    .foregroundStyle(.white)
                                            }
                                            .onAppear {
                                                livePulse = true
                                            }

                                        } else {

                                            TimelineView(
                                                .periodic(
                                                    from: .now,
                                                    by: 1
                                                )
                                            ) { context in

                                                Text(
                                                    countdownText(
                                                        from: context.date
                                                    )
                                                )
                                                .font(.system(size: 72))
                                                .bold()
                                                .fontDesign(.rounded)
                                                .foregroundStyle(.white)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 16)
                                    .frame(maxWidth: .infinity)
                                    .glassEffect(
                                        .regular
                                            .tint(
                                                isActuallyLive
                                                ? .red.opacity(0.2)
                                                : Color("AccentColor")
                                            )
                                            .interactive(true),

                                        in: RoundedRectangle(
                                            cornerRadius: 32,
                                            style: .continuous
                                        )
                                    )
                                }
                            }
                            
                            
                            // MARK: MVP Voting

                            if details.mvpVotingOpen {

                                VStack(alignment: .leading, spacing: 16) {

                                    HStack {

                                        VStack(alignment: .leading, spacing: 2) {

                                            Text("MVP Voting")
                                                .font(.largeTitle)
                                                .bold()
                                        }

                                        Spacer()

                                        Button {
                                            showMVPInfo = true

                                        } label: {
                                            Image(systemName: "info.circle")
                                                .font(.title3)
                                                .foregroundStyle(Color("AccentColor"))
                                        }
                                        .popover(isPresented: $showMVPInfo) {

                                            VStack(alignment: .leading, spacing: 16) {

                                                VStack(alignment: .leading, spacing: 4) {

                                                    Text("MVP Voting")
                                                        .font(.title2)
                                                        .bold()

                                                    Text("How it works")
                                                        .foregroundStyle(.secondary)
                                                }

                                                VStack(alignment: .leading, spacing: 12) {

                                                    Label(
                                                        "Vote for the best player in the match",
                                                        systemImage: "star.fill"
                                                    )

                                                    Label(
                                                        "MVP receives bonus rating points",
                                                        systemImage: "chart.line.uptrend.xyaxis"
                                                    )

                                                    Label(
                                                        "You can vote only once",
                                                        systemImage: "checkmark.circle"
                                                    )

                                                    Label(
                                                        "You cannot vote for yourself",
                                                        systemImage: "person.crop.circle.badge.xmark"
                                                    )
                                                }
                                                .font(.headline)

                                                Spacer()
                                            }
                                            .padding(20)
                                            .frame(width: 320)
                                            .presentationCompactAdaptation(.popover)
                                        }
                                    }

                                    VStack(spacing: 10) {

                                        ForEach(details.players) { player in

                                            MVPVoteRow(
                                                player: player,

                                                isCurrentUser: player.id == session.user?.id,

                                                disabled: details.hasVoted,

                                                isSelected: player.isVotedByCurrentUser,

                                                votesCount: player.mvpVotesCount,

                                                onVote: {
                                                    Task {
                                                        await vm.submitVote(
                                                            playerId: player.id
                                                        )
                                                    }
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            
                            //MARK: MVP Player
                            
                            if details.isProcessed,
                               let mvp = details.mvpPlayer {

                                VStack(alignment: .leading, spacing: 16) {

                                    HStack {

                                        VStack(alignment: .leading, spacing: 2) {

                                            Text("Match MVP")
                                                .font(.largeTitle)
                                                .bold()
                                        }

                                        Spacer()

                                        Image(systemName: "crown.fill")
                                            .font(.title)
                                            .foregroundStyle(.yellow)
                                    }

                                    HStack(spacing: 18) {

                                        AsyncImage(
                                            url: URL(string: mvp.avatarUrl ?? "")
                                        ) { image in

                                            image
                                                .resizable()
                                                .scaledToFill()

                                        } placeholder: {

                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .padding(12)
                                                .foregroundStyle(.white)
                                                .background(Color("AccentColor"))
                                        }
                                        .frame(width: 84, height: 84)
                                        .background(Color("AccentColor"))
                                        .clipShape(Circle())

                                        VStack(
                                            alignment: .leading,
                                            spacing: 8
                                        ) {

                                            Text(mvp.username)
                                                .font(.title2)
                                                .bold()

                                            HStack(spacing: 8) {

                                                Image(systemName: "star.fill")
                                                    .foregroundStyle(.yellow)

                                                Text("\(mvp.votesCount) votes")
                                                    .font(.headline)
                                                    .bold()
                                            }

                                            HStack(spacing: 8) {

                                                Image(systemName: "chart.line.uptrend.xyaxis")
                                                    .foregroundStyle(.green)

                                                Text("+20 Rating")
                                                    .font(.headline)
                                                    .bold()
                                                    .foregroundStyle(.green)
                                            }
                                        }

                                        Spacer()
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity)
                                    .glassEffect(
                                        .regular
                                            .tint(.yellow.opacity(0.12))
                                            .interactive(true),

                                        in: RoundedRectangle(
                                            cornerRadius: 28,
                                            style: .continuous
                                        )
                                    )
                                }
                            }
                            
                            // MARK: Teams
                            
                            VStack(alignment: .leading) {
                                Text("Teams")
                                    .font(.largeTitle)
                                    .bold()
                                
                                HStack {
                                    
                                    ZStack {
                                        
                                        ForEach(0..<3, id: \.self) { index in
                                            
                                            Group {
                                                if index < teamAlpha.count {
                                                    avatarView(teamAlpha[index])
                                                } else {
                                                    placeholderAvatar
                                                }
                                            }
                                            .zIndex(Double(3 - index))
                                            .offset(x: CGFloat(index * -26) + 26)
                                        }
                                    }
                                    .frame(width: 104)
                                    
                                    ZStack {
                                        Text("VS")
                                            .font(.system(size: 50, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                    }
                                    .frame(width: 100, height: 100)
                                    .glassEffect(.regular.tint(Color("AccentColor")).interactive(true), in: .circle)
                                    
                                    ZStack {
                                        
                                        ForEach(0..<3, id: \.self) { index in
                                            
                                            Group {
                                                if index < teamBeta.count {
                                                    avatarView(teamBeta[index])
                                                } else {
                                                    placeholderAvatar
                                                }
                                            }
                                            .offset(x: CGFloat(index * 26) - 26)
                                            .zIndex(Double(3 - index))
                                        }
                                    }
                                    .frame(width: 104)
                                
                                    
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .glassEffect(.regular.tint(Color("inversePrimary")).interactive(true),
                                             in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            }
                            
                            // MARK: Highlight players
                            
                            VStack(alignment: .leading) {
                                Text("Player Highlights")
                                    .font(.largeTitle)
                                    .bold()
                                
                                VStack {
                                    ZStack {
                                        
                                        highlightPlayer(
                                            player: topRatedPlayer,
                                            title: "Top Rated Player",
                                            icon: "star.fill",
                                            iconColor: .yellow
                                        )
                                        .offset(y: -50)
                                        
                                        highlightPlayer(
                                            player: mostActivePlayer,
                                            title: "Most Active Player",
                                            icon: "flame.fill",
                                            iconColor: .red
                                        )
                                        .offset(x: 100, y: 80)
                                        
                                        highlightPlayer(
                                            player: newestPlayer,
                                            title: "New Player",
                                            icon: "checkmark.seal.fill",
                                            iconColor: .green
                                        )
                                        .offset(x: -100, y: 80)
                                    }
                                    .frame(height: 250)
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .glassEffect(.regular.tint(Color("inversePrimary")).interactive(true),
                                             in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            }
                            
                            // MARK: PARK DETAILS
                            
                            VStack(alignment: .leading) {
                                
                                Text("Park Details")
                                    .font(.largeTitle)
                                    .bold()
                                
                                VStack(spacing: 16) {
                                    
                                    HStack {
                                        
                                        
                                        VStack (spacing: 2) {
                                            Text("Rating")
                                                .font(.system(.body, weight: .semibold))
                                                .foregroundStyle(.secondary)
                                            HStack (spacing: 8) {
                                                Image(systemName: "star.fill")
                                                    .symbolRenderingMode(.multicolor)
                                                
                                                Text(String(format: "%.1f", vm.details?.park.overallAvg ?? 0.0))
                                                    .font(.title3)
                                                    .bold()
                                            }
                                            
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        VStack (spacing: 2) {
                                            Text("Lightning")
                                                .font(.system(.body, weight: .semibold))
                                                .foregroundStyle(.secondary)
                                            HStack (spacing: 8) {
                                                Image(systemName: (vm.details?.park.hasLighting)! ? "lightbulb.max" : "lightbulb.slash")
                                                    .symbolRenderingMode(.multicolor)
                                                
                                                Text((vm.details?.park.hasLighting)! ? "Yes" : "No")
                                                    .font(.title3)
                                                    .bold()
                                            }
                                            
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    
                                    if let parkItem {
                                        
                                        ZStack {
                                            
                                            Map(
                                                position: .constant(
                                                    .region(region)
                                                ),
                                                interactionModes: [],
                                                selection: $selectedItem
                                            ) {
                                                Marker(
                                                    details.park.name,
                                                    systemImage: "trophy",
                                                    coordinate: parkItem.location.coordinate
                                                )
                                                .tag(parkItem)
                                                .annotationTitles(.hidden)
                                            }
                                            .allowsHitTesting(false)
                                            .tint(Color("AccentColor"))
                                            .onAppear {
                                                selectedItem = parkItem
                                            }
                                            
                                            Button {
                                                parkItem.openInMaps()
                                            } label: {
                                                HStack {
                                                    Image(systemName: "map.fill")
                                                    
                                                    Text("Open in Maps")
                                                        .bold()
                                                }
                                            }
                                            .offset(y: 60)
                                            .foregroundStyle(Color("AccentColor"))
                                            .buttonStyle(.glass)
                                        }
                                        .frame(height: 204)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 24)
                                        )
                                    }
                                }
                                .padding(.top, 16)
                                .frame(maxWidth: .infinity)
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
                            
                            //MARK: Weather
                            
                            VStack(alignment: .leading) {
                                Text("Weather")
                                    .font(.largeTitle)
                                    .bold()
                                
                                HStack {
                                    Spacer()
                                    HStack {
                                        Image(systemName: "thermometer.medium")
                                            .font(.system(size: 33))
                                        Text("\(Int(vm.weather?.temperature ?? 0))°C")
                                            .font(.title2)
                                            .bold()
                                            .fontDesign(.rounded)
                                    }
                                    Spacer()
                                    HStack {
                                        Image(systemName: "wind")
                                            .font(.system(size: 33))
                                        Text("\(Int(vm.weather?.windSpeed ?? 0)) km/h")
                                            .font(.title2)
                                            .bold()
                                            .fontDesign(.rounded)
                                    }
                                    Spacer()
                                    HStack {
                                        Image(systemName: "cloud.rain.fill")
                                            .font(.system(size: 33))
                                        Text("\(vm.weather?.rainChance ?? 0)%")
                                            .font(.title2)
                                            .bold()
                                            .fontDesign(.rounded)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .glassEffect(.regular.tint(Color("inversePrimary")).interactive(true),
                                             in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 160)
                    }
                    .ignoresSafeArea()
                    
                    // MARK: JOIN BUTTON
                    
                    if !isActuallyLive &&
                       !details.isFinished &&
                       (isOpen || isJoined) {
                        Button(isJoined ? "Manage Team" : "Join to Game") {
                            showJoinSheet = true
                        }
                        .controlSize(.large)
                        .font(.title2)
                        .bold()
                        .buttonStyle(.glassProminent)
                        .tint(.indigo)
                        .padding(.bottom, 10)
                    }
                }
                
            } else if let error = vm.errorMessage {
                
                Text(error)
                
            } else {
                
                Text("No Data")
            }
        }
        .task {
            await vm.load(gameId: gameId)
        }
        .fullScreenCover(isPresented: $showJoinSheet) {

            if let details,
               let userId = session.user?.id {

                JoinGameSheetView(
                    details: details,
                    currentUserId: userId,
                    
                    onJoin: { team in
                        Task {
                            await vm.joinGame(
                                gameId: gameId,
                                team: team
                            )
                        }
                    },
                    
                    onLeave: {
                        Task {
                            await vm.leaveGame(
                                gameId: gameId
                            )
                        }
                    }
                )
            }
        }
    }
}


struct MVPVoteRow: View {

    // MARK: - Properties

    let player: Player
    let isCurrentUser: Bool
    let disabled: Bool
    let isSelected: Bool

    let votesCount: Int

    let onVote: () -> Void

    // MARK: - Rank

    private var rank: Rank {
        RankHelper.getRank(
            rating: player.rating
        )
    }

    // MARK: - Body

    var body: some View {

        Button {

            if !isSelected {
                onVote()
            }

        } label: {

            HStack(spacing: 14) {

                avatarView

                infoView

                Spacer()

                votesView

                actionView
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .overlay {
                selectionBorder
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 24
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(
            (!isSelected && disabled)
            || isCurrentUser
        )
    }

    // MARK: - Info

    private var infoView: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(player.username)
                .font(.headline)
                .bold()

            rankBadge
        }
    }

    // MARK: - Rank Badge

    private var rankBadge: some View {

        Text(rank.title)
            .font(.caption)
            .bold()
            .foregroundStyle(rank.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(rank.borderColor)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
                )
            )
    }

    // MARK: - Votes

    @ViewBuilder
    private var votesView: some View {

        if votesCount > 0 {

            HStack(spacing: 6) {

                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)

                Text("\(votesCount)")
                    .font(.headline)
                    .bold()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.yellow.opacity(0.14))
            .clipShape(Capsule())
        }
    }

    // MARK: - Action

    @ViewBuilder
    private var actionView: some View {

        if isCurrentUser {

            Text("You")
                .font(.headline)
                .bold()
                .foregroundStyle(.secondary)

        } else if disabled {

            if isSelected {

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color("AccentColor"))
                    .font(.title2)
            }

        } else {

            Text("Vote")
                .font(.headline)
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color("AccentColor"))
                .clipShape(Capsule())
        }
    }

    // MARK: - Avatar

    private var avatarView: some View {

        AsyncImage(
            url: URL(
                string: player.avatarUrl ?? ""
            )
        ) { phase in

            switch phase {

            case .success(let image):

                image
                    .resizable()
                    .scaledToFill()

            default:

                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .foregroundStyle(.white)
                    .background(Color("AccentColor"))
            }
        }
        .frame(width: 52, height: 52)
        .background(Color("AccentColor"))
        .clipShape(Circle())
    }

    // MARK: - Background

    private var backgroundColor: Color {

        isSelected
        ? Color("AccentColor").opacity(0.15)
        : .white.opacity(0.7)
    }

    // MARK: - Border

    private var selectionBorder: some View {

        RoundedRectangle(
            cornerRadius: 24
        )
        .stroke(
            isSelected
            ? Color("AccentColor")
            : .clear,
            lineWidth: 2
        )
    }
}

