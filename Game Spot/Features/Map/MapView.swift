import SwiftUI
import MapKit

struct MapView: View {

    // MARK: - View Models

    @StateObject private var viewModel =
        MapViewModel()

    @StateObject private var parkViewModel =
        ParkDetailsViewModel()

    // MARK: - Map State

    @State private var selectedPark: Park?

    @State private var position:
        MapCameraPosition = .automatic

    @State private var isMovingToSelectedPin = false

    // MARK: - Bottom Sheet

    @State private var showBottomSheet = false

    @State private var sheetDetent:
        PresentationDetent = .height(350)

    // MARK: - Body

    var body: some View {

        mapContent
            .sheet(
                isPresented: $showBottomSheet
            ) {

                bottomSheet
            }
            .mapControls {

                MapUserLocationButton()

                MapCompass()

                MapScaleView()
            }
            .mapStyle(
                .standard(
                    elevation: .realistic
                )
            )
            .onChange(
                of: selectedPark
            ) { _, newValue in

                handleParkSelection(
                    newValue
                )
            }
            .onMapCameraChange { _ in

                handleMapCameraChange()
            }
            .task {
                
                await viewModel.load()
            }
    }
}

// MARK: - Components

private extension MapView {

    var mapContent: some View {

        Map(
            position: $position,
            selection: $selectedPark
        ) {

            parksMarkers

            UserAnnotation()
        }
    }

    var parksMarkers: some MapContent {

        ForEach(viewModel.parks) { park in

            Marker(
                park.name,
                systemImage: "trophy",
                coordinate: park.coordinate
            )
            .tag(park)
            .annotationTitles(.hidden)
        }
    }

    var bottomSheet: some View {

        ParkInfoView(
            selectedPark: $selectedPark,
            selectedDetent: $sheetDetent,
            viewModel: parkViewModel
        )
        .presentationDetents(
            [
                .height(90),
                .height(350),
                .large
            ],
            selection: $sheetDetent
        )
        .presentationBackgroundInteraction(
            .enabled
        )
    }
}

// MARK: - Actions

private extension MapView {

    func handleParkSelection(
        _ park: Park?
    ) {

        showBottomSheet = park != nil

        sheetDetent = .height(350)

        guard let coordinate =
                park?.coordinate else {
            return
        }

        isMovingToSelectedPin = true

        withAnimation(
            .easeInOut(duration: 0.45)
        ) {

            position = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.01,
                        longitudeDelta: 0.01
                    )
                )
            )
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 2
        ) {

            isMovingToSelectedPin = false
        }
    }

    func handleMapCameraChange() {

        guard !isMovingToSelectedPin else {
            return
        }

        guard sheetDetent != .height(90)
        else {
            return
        }

        withAnimation(
            .easeInOut(duration: 0.45)
        ) {

            sheetDetent = .height(90)
        }
    }
}

#Preview {

    MapView()
}
