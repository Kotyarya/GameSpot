//
//  MainTabView.swift
//  Game Spot
//
//  Created by Maksim Aksamitnuy on 29/04/2026.
//

import SwiftUI
internal import Auth

@MainActor
struct MainTabView: View {

    // MARK: - Environment

    @EnvironmentObject private var router:
        AppRouter

    private let mapViewModel: MapViewModel
    private let parkViewModel: ParkDetailsViewModel
    private let gamesViewModel: GamesViewModel
    private let profileViewModel: ProfileViewModel

    init(
        mapViewModel: MapViewModel = MapViewModel(),
        parkViewModel: ParkDetailsViewModel = ParkDetailsViewModel(),
        gamesViewModel: GamesViewModel = GamesViewModel(),
        profileViewModel: ProfileViewModel = ProfileViewModel()
    ) {
        self.mapViewModel = mapViewModel
        self.parkViewModel = parkViewModel
        self.gamesViewModel = gamesViewModel
        self.profileViewModel = profileViewModel
    }

    // MARK: - Body

    var body: some View {

        TabView(
            selection: $router.selectedTab
        ) {

            mapTab

            gamesTab

            profileTab
        }
        .tint(Color("AccentColor"))
    }
}

// MARK: - Tabs

private extension MainTabView {

    var mapTab: some View {

        NavigationStack(
            path: $router.mapPath
        ) {

            MapView(
                viewModel: mapViewModel,
                parkViewModel: parkViewModel
            )
                .navigationDestination(
                    for: Route.self,
                    destination: destination
                )
        }
        .tabItem {

            Label(
                "Map",
                systemImage: "map.fill"
            )
        }
        .tag(AppRouter.Tab.map)
    }

    var gamesTab: some View {

        NavigationStack(
            path: $router.gamesPath
        ) {

            GamesView(
                mode: .myGames,
                viewModel: gamesViewModel
            )
            .navigationDestination(
                for: Route.self,
                destination: destination
            )
        }
        .tabItem {

            Label(
                "My Games",
                systemImage: "sportscourt.fill"
            )
        }
        .tag(AppRouter.Tab.games)
    }

    var profileTab: some View {

        NavigationStack {

            ProfileView(viewModel: profileViewModel)
        }
        .tabItem {

            Label(
                "Profile",
                systemImage: "person.crop.circle"
            )
        }
        .tag(AppRouter.Tab.profile)
    }
}
