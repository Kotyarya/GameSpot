#if DEBUG

import SwiftUI

@MainActor
private struct ParkInfoPreviewHost: View {
    @State private var selectedPark: Park? = PreviewFixtures.park
    @State private var detent: PresentationDetent = .height(350)
    @StateObject private var viewModel = PreviewFactory.parkDetails()

    var body: some View {
        ParkInfoView(
            selectedPark: $selectedPark,
            selectedDetent: $detent,
            viewModel: viewModel
        )
        .environmentObject(PreviewFactory.session())
        .environmentObject(AppRouter())
        .frame(height: 700)
    }
}

#Preview("Map · Loaded") {
    MapView(
        viewModel: PreviewFactory.map(),
        parkViewModel: PreviewFactory.parkDetails()
    )
    .environmentObject(AppRouter())
    .environmentObject(PreviewFactory.session())
}

#Preview("Map · Empty") {
    MapView(
        viewModel: PreviewFactory.map(parks: .success([])),
        parkViewModel: PreviewFactory.parkDetails()
    )
    .environmentObject(AppRouter())
    .environmentObject(PreviewFactory.session())
}

#Preview("Map · Error") {
    MapView(
        viewModel: PreviewFactory.map(parks: .failure(PreviewFailure.offline)),
        parkViewModel: PreviewFactory.parkDetails()
    )
    .environmentObject(AppRouter())
    .environmentObject(PreviewFactory.session())
}

#Preview("Park Details") {
    ParkInfoPreviewHost()
}

#endif
