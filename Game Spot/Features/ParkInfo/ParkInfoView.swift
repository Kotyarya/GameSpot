import SwiftUI
import Foundation
import MapKit
internal import Auth

struct ParkInfoView: View {

    // MARK: - State

    @State private var isExpanded = true

    @State private var showRating = false

    @State private var quality = 0
    @State private var facilities = 0
    @State private var activity = 0

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    @EnvironmentObject
    var session: SessionManager

    @EnvironmentObject
    var router: AppRouter

    // MARK: - Bindings

    @Binding var selectedPark: Park?

    @Binding var selectedDetent: PresentationDetent

    // MARK: - ViewModel

    @ObservedObject
    var viewModel: ParkDetailsViewModel

    // MARK: - Validation

    private var isValid: Bool {

        quality > 0
        && facilities > 0
        && activity > 0
    }

    // MARK: - Body

    var body: some View {

        ZStack(alignment: .topTrailing) {

            contentView

            closeButton
        }
        .task(id: selectedPark?.id) {

            guard let parkId = selectedPark?.id,
                  let userId = session.user?.id else {
                return
            }

            await viewModel.load(
                parkId: parkId
            )

            await viewModel.checkIfRated(
                userId: userId,
                parkId: parkId
            )
        }
    }
}

// MARK: - Content

private extension ParkInfoView {

    var contentView: some View {

        ScrollViewReader { proxy in

            ScrollView {

                Color.clear
                    .frame(height: 1)
                    .id("top")

                VStack(
                    alignment: .center,
                    spacing: 32
                ) {

                    headerSection

                    actionButtonsSection

                    mainInfoSection

                    photosSection

                    sportsSection

                    ratingsSection

                    hoursSection

                    bottomButtonsSection
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .top
                )
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 28)
            }
            .onChange(of: selectedDetent) {

                withAnimation(
                    .easeInOut(duration: 0.2)
                ) {

                    proxy.scrollTo(
                        "top",
                        anchor: .top
                    )
                }
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Header

private extension ParkInfoView {

    var headerSection: some View {

        VStack {

            Text(
                viewModel.details?.park.name
                ?? "Park Name"
            )
            .font(.title2)
            .bold()

            Text(
                viewModel.details?.park.address
                ?? "Address"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .bold()
        }
    }
}

// MARK: - Action Buttons

private extension ParkInfoView {

    var actionButtonsSection: some View {

        HStack {

            createGameButton

            viewGamesButton
        }
    }

    var createGameButton: some View {

        Button {

            guard let details = viewModel.details else {
                return
            }

            selectedPark = nil

            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.2
            ) {

                router.push(
                    .createGame(
                        park: details.park,
                        sports: details.sports
                    )
                )
            }

        } label: {

            VStack(
                alignment: .center,
                spacing: 4
            ) {

                Image(systemName: "plus")

                Text("Create Game")
                    .font(
                        .system(
                            .body,
                            weight: .semibold
                        )
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(Color("AccentColor"))
    }

    var viewGamesButton: some View {

        Button {

            if let parkId = selectedPark?.id,
               let parkName = selectedPark?.name {

                selectedPark = nil

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.2
                ) {

                    router.push(
                        .parkGames(
                            id: parkId,
                            name: parkName
                        )
                    )
                }
            }

        } label: {

            VStack(
                alignment: .center,
                spacing: 4
            ) {

                Image(systemName: "list.bullet")

                Text("View Games")
                    .font(
                        .system(
                            .body,
                            weight: .semibold
                        )
                    )
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .tint(
            Color("AccentColor")
                .opacity(0.2)
        )
        .foregroundStyle(Color("AccentColor"))
    }
}

// MARK: - Main Info

private extension ParkInfoView {

    var mainInfoSection: some View {

        HStack(spacing: 0) {

            hoursInfoCard

            ratingInfoCard

            lightingInfoCard
        }
    }

    var hoursInfoCard: some View {

        VStack(spacing: 2) {

            Text("Hours")
                .font(
                    .system(
                        .body,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)

            if let hours = viewModel.details?.hours,
               isParkOpen(hours: hours) {

                Text("Open")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.green)

            } else {

                Text("Closed")
                    .font(.title3)
                    .bold()
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity)
    }

    var ratingInfoCard: some View {

        VStack(spacing: 2) {

            Text("Rating")
                .font(
                    .system(
                        .body,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {

                Image(systemName: "star.fill")
                    .symbolRenderingMode(.multicolor)

                Text(
                    String(
                        format: "%.1f",
                        viewModel.details?.rating?.overallAvg ?? 0
                    )
                )
                .font(.title3)
                .bold()
            }
        }
        .frame(maxWidth: .infinity)
    }

    var lightingInfoCard: some View {

        VStack(spacing: 2) {

            Text("Lightning")
                .font(
                    .system(
                        .body,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {

                Image(
                    systemName:
                        viewModel.details?.park.hasLighting == true
                    ? "lightbulb.max"
                    : "lightbulb.slash"
                )
                .symbolRenderingMode(.multicolor)

                Text(
                    viewModel.details?.park.hasLighting == true
                    ? "Yes"
                    : "No"
                )
                .font(.title3)
                .bold()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Photos

private extension ParkInfoView {

    var photosSection: some View {

        Group {

            if let images = viewModel.details?.images,
               !images.isEmpty {

                photosCarousel(images)

            } else {

                placeholderPhotos
            }
        }
    }

    func photosCarousel(
        _ images: [ParkImage]
    ) -> some View {

        let sortedImages = images.sorted {
            $0.isMain && !$1.isMain
        }

        return ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack(spacing: 12) {

                ForEach(sortedImages) { img in

                    AsyncImage(
                        url: URL(string: img.imageUrl)
                    ) { phase in

                        switch phase {

                        case .success(let image):

                            image
                                .resizable()
                                .scaledToFill()

                        case .failure(_), .empty:

                            placeholderPhoto

                        @unknown default:

                            EmptyView()
                        }

                    }
                    .frame(width: 138, height: 138)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 24
                        )
                    )
                }
            }
        }
    }

    var placeholderPhotos: some View {

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack {

                ForEach(0..<4) { _ in

                    placeholderPhoto
                        .frame(
                            width: 138,
                            height: 138
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 24
                            )
                        )
                }
            }
        }
    }

    var placeholderPhoto: some View {

        ZStack {

            Color("AccentColor")

            Image(systemName: "photo")
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Sports

private extension ParkInfoView {

    var sportsSection: some View {

        VStack(alignment: .leading) {

            Text("Play Options")
                .font(
                    .system(
                        .title,
                        weight: .bold
                    )
                )

            HStack {

                if let sports = viewModel.details?.sports {

                    ForEach(sports) { sport in

                        Spacer()

                        VStack {

                            SportGlassPin(
                                sport: sport,
                                tint: Color("AccentColor")
                            )

                            Text(
                                sport.name.capitalized
                            )
                            .font(.callout)
                            .bold()
                        }

                        Spacer()
                    }
                }
            }
            .padding(12)
            .glassEffect(
                .regular
                    .tint(.clear)
                    .interactive(true),

                in: RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

// MARK: - Ratings

private extension ParkInfoView {

    var ratingsSection: some View {

        VStack(alignment: .leading) {

            Text("Ratings")
                .font(
                    .system(
                        .title,
                        weight: .bold
                    )
                )

            VStack(spacing: 16) {

                ratingRow(
                    "Quality",
                    viewModel.details?.rating?.qualityAvg ?? 0,
                    viewModel.details?.rating?.qualityCount ?? 0
                )

                ratingRow(
                    "Facilities",
                    viewModel.details?.rating?.facilitiesAvg ?? 0,
                    viewModel.details?.rating?.facilitiesCount ?? 0
                )

                ratingRow(
                    "Activity",
                    viewModel.details?.rating?.activityAvg ?? 0,
                    viewModel.details?.rating?.activityCount ?? 0
                )
            }
            .padding(12)
            .glassEffect(
                .regular
                    .tint(.clear)
                    .interactive(true),

                in: RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

// MARK: - Hours

private extension ParkInfoView {

    var hoursSection: some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            Text("Hours")
                .font(.title.bold())

            HStack {

                if let hours = viewModel.details?.hours,
                   isParkOpen(hours: hours) {

                    Text("Open")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.green)

                } else {

                    Text("Closed")
                        .font(.title2)
                        .bold()
                        .foregroundStyle(.red)
                }

                Spacer()

                Text(
                    todayHours(
                        from: viewModel.details?.hours ?? []
                    )
                )
                .font(.title2)
            }

            Divider()

            VStack(
                alignment: .leading,
                spacing: 16
            ) {

                Button {

                    withAnimation(
                        .easeInOut(duration: 0.25)
                    ) {

                        isExpanded.toggle()
                    }

                } label: {

                    HStack {

                        Text("Normal Hours")
                            .font(.title2)
                            .foregroundStyle(.gray)

                        Spacer()

                        Image(systemName: "chevron.up")
                            .rotationEffect(
                                .degrees(
                                    isExpanded ? 0 : 180
                                )
                            )
                            .foregroundStyle(.gray)
                    }
                }
                .buttonStyle(.plain)

                if isExpanded {

                    VStack(spacing: 20) {

                        if let hours = viewModel.details?.hours {

                            ForEach(hours) { item in

                                HStack {

                                    Text(
                                        dayName(item.dayOfWeek)
                                    )
                                    .font(.title2)

                                    Spacer()

                                    if item.isClosed {

                                        Text("Closed")
                                            .font(.title2)
                                            .foregroundStyle(.red)

                                    } else {

                                        Text(
                                            "\(formatTime(item.openHour))-\(formatTime(item.closeTime))"
                                        )
                                        .font(.title2)
                                    }
                                }
                            }
                        }
                    }
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )
                }
            }
        }
    }
}

// MARK: - Bottom Buttons

private extension ParkInfoView {

    var bottomButtonsSection: some View {

        VStack(spacing: 8) {

            if !viewModel.hasRated {

                rateParkButton
            }

            if showRating {

                ratingFormSection
            }

            openMapsButton
        }
    }

    var rateParkButton: some View {

        Button {

            withAnimation(
                .spring(
                    response: 0.4,
                    dampingFraction: 0.8
                )
            ) {

                showRating.toggle()
            }

        } label: {

            HStack(
                alignment: .center,
                spacing: 4
            ) {

                Image(systemName: "star.fill")
                    .font(.system(size: 18))

                Text("Rate this park")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.glassProminent)
        .tint(
            Color("AccentColor")
                .opacity(0.2)
        )
        .foregroundStyle(Color("AccentColor"))
    }

    var ratingFormSection: some View {

        VStack(spacing: 20) {

            starsRow("Quality", $quality)

            starsRow("Facilities", $facilities)

            starsRow("Activity", $activity)

            submitRatingButton
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
        .transition(
            .move(edge: .top)
            .combined(with: .opacity)
        )
        .frame(maxWidth: .infinity)
    }

    var submitRatingButton: some View {

        Button {

            if isValid,
               let parkId = viewModel.details?.park.id,
               let userId = session.user?.id {

                Task {

                    await viewModel.submitRating(
                        userId: userId,
                        parkId: parkId,
                        quality: quality,
                        facilities: facilities,
                        activity: activity
                    )

                    await viewModel.checkIfRated(
                        userId: userId,
                        parkId: parkId
                    )

                    withAnimation(
                        .spring(
                            response: 0.4,
                            dampingFraction: 0.8
                        )
                    ) {

                        showRating.toggle()

                        quality = 0
                        facilities = 0
                        activity = 0
                    }
                }
            }

        } label: {

            Text("Submit")
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .disabled(!isValid)
        .buttonStyle(.glassProminent)
        .tint(Color("AccentColor"))
        .foregroundStyle(.white)
    }

    var openMapsButton: some View {

        Button {

            openInMaps()

        } label: {

            HStack(
                alignment: .center,
                spacing: 4
            ) {

                Image(systemName: "map.fill")
                    .font(.system(size: 18))

                Text("Open in maps")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.glassProminent)
        .tint(
            Color("AccentColor")
                .opacity(0.2)
        )
        .foregroundStyle(Color("AccentColor"))
    }
}

// MARK: - Close Button

private extension ParkInfoView {

    var closeButton: some View {

        Button {

            withAnimation(.easeOut) {

                dismiss()

                selectedDetent = .height(350)

                selectedPark = nil
            }

        } label: {

            Image(systemName: "xmark")
                .font(.system(size: 22))
                .fontWeight(.regular)
                .frame(width: 32, height: 32)
                .foregroundStyle(.black)
        }
        .padding(.trailing, 20)
        .padding(.top, 25)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
    }
}

// MARK: - Helpers

private extension ParkInfoView {

    func ratingRow(
        _ title: String,
        _ value: Double,
        _ count: Int
    ) -> some View {

        HStack {

            VStack(alignment: .leading) {

                Text(title)
                    .bold()

                Text("\(count) Ratings")
                    .font(.caption)
            }

            Spacer()

            HStack {

                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)

                Text(
                    "\(value, specifier: "%.1f")"
                )
                .bold()
            }
        }
    }

    func starsRow(
        _ title: String,
        _ rating: Binding<Int>
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(title)
                .font(.headline)

            HStack {

                ForEach(1...5, id: \.self) { index in

                    Image(
                        systemName:
                            index <= rating.wrappedValue
                        ? "star.fill"
                        : "star"
                    )
                    .font(.title2)
                    .foregroundStyle(.yellow)
                    .scaleEffect(
                        index <= rating.wrappedValue
                        ? 1.1
                        : 1
                    )
                    .animation(
                        .spring(response: 0.25),
                        value: rating.wrappedValue
                    )
                    .onTapGesture {

                        rating.wrappedValue = index

                        UIImpactFeedbackGenerator(
                            style: .light
                        )
                        .impactOccurred()
                    }
                }
            }
        }
    }

    func isParkOpen(
        hours: [ParkHour]
    ) -> Bool {

        let calendar = Calendar.current

        let now = Date()

        let weekday = calendar.component(
            .weekday,
            from: now
        )

        let normalizedDay =
            weekday == 1
            ? 7
            : weekday - 1

        guard let today = hours.first(
            where: {
                $0.dayOfWeek == normalizedDay
            }
        ) else {
            return false
        }

        if today.isClosed {
            return false
        }

        guard let open = today.openHour,
              let close = today.closeTime else {
            return false
        }

        let openParts =
            formatTime(open)
                .split(separator: ":")

        let closeParts =
            formatTime(close)
                .split(separator: ":")

        guard let openHour = Int(openParts[0]),
              let openMinute = Int(openParts[1]),
              let closeHour = Int(closeParts[0]),
              let closeMinute = Int(closeParts[1]) else {
            return false
        }

        let nowHour =
            calendar.component(
                .hour,
                from: now
            )

        let nowMinute =
            calendar.component(
                .minute,
                from: now
            )

        let nowTotal =
            nowHour * 60 + nowMinute

        let openTotal =
            openHour * 60 + openMinute

        let closeTotal =
            closeHour * 60 + closeMinute

        return nowTotal >= openTotal
            && nowTotal <= closeTotal
    }

    func todayHours(
        from hours: [ParkHour]
    ) -> String {

        let calendar = Calendar.current

        let now = Date()

        let weekday = calendar.component(
            .weekday,
            from: now
        )

        let normalizedDay =
            weekday == 1
            ? 7
            : weekday - 1

        guard let today = hours.first(
            where: {
                $0.dayOfWeek == normalizedDay
            }
        ) else {
            return "--:--"
        }

        if today.isClosed {
            return "Closed"
        }

        let open =
            formatTime(
                today.openHour ?? "--:--"
            )

        let close =
            formatTime(
                today.closeTime ?? "--:--"
            )

        return "\(open)-\(close)"
    }

    func dayName(
        _ day: Int
    ) -> String {

        [
            "Monday",
            "Tuesday",
            "Wednesday",
            "Thuesday",
            "Friday",
            "Saturday",
            "Sunday"
        ][max(0, min(day - 1, 6))]
    }

    func openInMaps() {

        guard let park = viewModel.details?.park else {
            return
        }

        let location = CLLocation(
            latitude: park.latitude,
            longitude: park.longitude
        )

        let mapItem = MKMapItem(
            location: location,
            address: nil
        )

        mapItem.name = park.name

        mapItem.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }
}
