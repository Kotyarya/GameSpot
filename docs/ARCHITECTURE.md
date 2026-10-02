# GameSpot Architecture

This document describes the current versioned client and backend architecture in the repository.

## System Overview

GameSpot is a feature-oriented SwiftUI application with an MVVM-style separation. There is no separate repository or domain layer: each ViewModel talks to a narrow service protocol whose production implementation uses the shared Supabase client or an external HTTP API.

```text
SwiftUI View
    │ user action / .task / binding
    ▼
@MainActor ObservableObject ViewModel
    │ async/await through a narrow protocol
    ▼
Service / Realtime service / Manager
    ├── Supabase Swift SDK ── Auth / PostgREST / RPC / Storage / Realtime
    ├── URLSession ───────── Open-Meteo
    └── CoreLocation ─────── foreground location on device
                               │
                               ▼
                    Supabase Postgres / Edge Function
```

The protocols are deliberately small testing seams rather than a complete dependency container. Production defaults still use shared service instances.

## Application Startup and Global State

`Game_SpotApp` creates three `@StateObject` instances:

- `SessionManager` owns the session, current user, profile, and application state;
- `AppRouter` owns the selected tab and separate `NavigationPath` values for Map and My Games;
- `AuthLinkCoordinator` handles authentication and recovery deep links.

They are injected into `RootView` through `environmentObject`.

`SessionManager.appState` is a computed state machine:

```text
session not checked -> loading
no Auth user       -> auth
profile load error -> loadError + Retry
not onboarded      -> onboarding
profile incomplete -> profileSetup
ready              -> main
```

Auth-link processing has priority in `RootView`. The app displays a loader while a link is exchanged for a session, opens `PasswordRecoveryView` for recovery links, and otherwise chooses a screen from `SessionManager.appState`.

Sign-out, successful account deletion, and completed recovery clear the local user and profile and return the app to authentication. A normal sign-in or sign-up calls `refreshUser()` and then loads `profiles`.

## Navigation

After authentication, `MainTabView` exposes three tabs:

- Map uses its own `NavigationStack` and `mapPath`;
- My Games uses its own `NavigationStack` and `gamesPath`;
- Profile uses a local `NavigationStack`; Settings and its child screens use local `NavigationLink` values rather than `AppRouter` routes.

The typed `Route` enum supports `.myGames`, `.parkGames(id:name:)`, `.game(UUID)`, and `.createGame(park:sports:)`. `destination(_:)` constructs the final screen. Profile navigation to Settings, Privacy Policy, and Blocked Users remains local.

## Layers and Responsibilities

### Views

Views own layout, presentation state, navigation, and forwarding user actions to ViewModels. Business validation belongs in ViewModels or the backend, although large views still contain presentation logic such as park status, countdowns, action visibility, and formatting.

| Screen | Purpose |
| --- | --- |
| `AuthView` | Sign-in, sign-up, confirmation/resend, and password-reset entry |
| `OnBoardingView` | Introductory carousel and foreground location permission |
| `ProfileSetupView` | Username, favorite sport, and optional avatar |
| `MapView` | Active park map and marker selection |
| `ParkInfoView` | Venue details, ratings, games, and create action |
| `GamesView` | Games for the current user or selected park |
| `CreateGameView` | Sport/time selection and game creation |
| `GameInfoView` | Teams, weather, Join/Leave, MVP voting, and match states; blocked players remain anonymous, non-interactive roster rows |
| `JoinGameSheetView` | Team selection or leaving a match |
| `ProfileView` / `PublicProfileView` | Shared profile components; the private profile adds Edit/avatar actions, while the public profile adds Report/Block |
| `SettingsView` | Privacy Policy, Blocked Users, support/about, sign-out, and account deletion |
| `PasswordResetRequestView` | Recovery-email request |
| `PasswordRecoveryView` | New password after a recovery deep link |

`ContentStateView` provides the shared production error, empty, and retry presentation. `LoadingView` handles full-screen loading.

### ViewModels

| ViewModel | Primary responsibility | Dependencies |
| --- | --- | --- |
| `AuthViewModel` | Email normalization, sign-in/up, confirmation state | `AuthServing` |
| `ProfileSetupViewModel` | Sports, debounced username checks, avatar and profile setup | `ProfileSetupServing`, `SportFetching`, `AvatarStoring` |
| `MapViewModel` | Active parks and load errors | `ParksFetching` |
| `ParkDetailsViewModel` | Parallel detail loading, rating state, stale-response protection | `ParkDetailsServing` |
| `GamesViewModel` | My Games/Park mode, section data, Realtime reload | `GamesFetching`, `GamesRealtimeSubscribing` |
| `CreateGameViewModel` | Client validation and create RPC | `GameCreating` |
| `GameInfoViewModel` | Details, optional weather, Join/Leave/Vote, Realtime | `GameInfoServing`, `WeatherFetching`, `GameInfoRealtimeSubscribing` |
| `ProfileViewModel` | Profile, stats, recent matches, avatar actions, Realtime | `ProfileFetching`, `ProfileRealtimeSubscribing`, avatar protocols |
| `PublicProfileViewModel` | Read-only profile and sport statistics for another player | `ProfileFetching` |
| `AccountDeletionViewModel` | Single-flight deletion and user-safe errors | `AccountDeleting` |
| `PasswordResetRequestViewModel` | Neutral recovery-request result | `PasswordRecoveryServing` |
| `PasswordRecoveryViewModel` | Password policy and update | `PasswordRecoveryServing` |

All ViewModels run on `@MainActor`, so `@Published` state changes are serialized on the UI actor.

### Services and Managers

| Component | Responsibility |
| --- | --- |
| `SupabaseService` | Single `SupabaseClient`, Auth redirect, and publishable configuration |
| `AuthService` | Email/password Auth, resend, recovery, and PKCE session exchange |
| `ProfileService` | Profiles, sport statistics, recent matches, and setup flags |
| `GameService` | Client-facing game RPCs |
| `ParkService` | Direct catalog reads and rating RPCs |
| `SportService` | Sports catalog |
| `SupabaseAvatarStorageService` | `{userId}/avatar.jpg` upload, removal, and public URL |
| `AccountDeletionService` | JWT-authenticated DELETE request to the Edge Function |
| `WeatherService` | Open-Meteo hourly forecast and nearest-hour selection |
| `LocationManager` | When-in-use permission and Core Location updates |
| Realtime services | Channel lifecycle and reload callbacks |

`AppConfiguration` reads `SupabaseURL` and `SupabasePublishableKey` from Info.plist and stops startup when either value is missing or invalid. The iOS app never uses a service-role key.

## Models

`Decodable` models mirror table and RPC payloads and use `CodingKeys` for snake_case:

- `Park`, `ParkDetails`, `ParkHour`, `ParkImage`, `ParkRating`, `ParkShort`;
- `Sport`, `SportType`;
- `Game`, `GameDetails`, `MVPPlayer`;
- `Profile`, `Player`, `RecentMatch`;
- `UserSportStats`;
- `Weather` and Open-Meteo transport DTOs.

`Team` maps exactly to the Postgres enum values `Team Alpha` and `Team Beta`.

## Main Data Flows

### Map and Park

```text
MapView -> MapViewModel.load -> ParkService.fetchParks
        -> SELECT public.parks WHERE is_active = true

ParkInfoView -> ParkDetailsViewModel.load
             -> parallel reads from parks, parks_sports+sports,
                parks_hour, parks_images, and parks_ratings
```

MapKit processes device coordinates locally. They are not sent to Supabase.

### Games

```text
GamesView -> GamesViewModel.load
          -> get_user_games or get_games_by_park RPC
          -> GameSectionBuilder(Calendar, now, Locale)

CreateGameView -> CreateGameViewModel -> create_game RPC
               -> game and creator membership in one server function
```

### Details, Teams, and MVP

```text
GameInfoView -> get_game_details RPC -> GameDetails
             -> Open-Meteo -> optional Weather

JoinGameSheetView -> join/leave RPC -> details reload
MVPVoteRow        -> vote_mvp RPC -> Realtime event -> details reload
```

The backend, not the UI, is the source of truth for time, capacity, membership, voting, and rewards.

### Profile and Avatar

```text
ProfileView -> profiles / user_sport_stats / get_recent_matches

selected UIImage -> AvatarImageEncoder (max 1024 px, JPEG <= 5 MiB)
                 -> Storage upsert {userId}/avatar.jpg
                 -> ProfileService.updateAvatar
                 -> local model update + Realtime
```

Profile Setup performs the same operations sequentially. Storage and the profile update are not one database transaction, but retry is safe because the upload uses upsert.

### Account Deletion

```text
ProfileView -> SettingsView -> AccountDeletionViewModel
  -> DELETE /functions/v1/delete-account
  -> gateway verifies JWT
  -> remove avatar
  -> service-role delete_user_data(user from claims)
  -> Auth admin deleteUser
  -> client clears local session after deleted=true
```

## Realtime Updates

Postgres Changes payloads normally act as invalidation signals. The client reloads the authoritative RPC or table result rather than reconstructing domain state from a partial event.

| Context | Tables | Reaction |
| --- | --- | --- |
| Games list | `games`, `game_members` | Reload the current mode after any relevant action |
| Game details | `games`, `game_members`, `game_mvp_votes` | Filter by `gameId`, then reload details |
| Profile | `profiles`, `user_sport_stats` | Filter by `userId`; decode profile or reload stats/recent matches |

Every service instance receives a unique channel. Handlers are installed before `subscribeWithError()`. Deinitialization unsubscribes, cancels subscriptions, and removes the channel from the client.

## Business-Logic Boundaries

- security, ownership, capacity, time, lifecycle, rewards, rating aggregation, and deletion live in PostgreSQL functions, RLS, grants, or the Edge Function;
- request orchestration and user-safe UI state live in ViewModels;
- image preparation, date grouping, and password rules live in small production helpers;
- layout, formatting, countdowns, and opening-hours presentation live in SwiftUI views and helpers.

See [DATABASE.md](DATABASE.md) for backend details and [FEATURES.md](FEATURES.md) for user flows.

## Known Architectural Trade-offs

- production dependencies use singleton defaults rather than a complete composition root;
- large SwiftUI files such as `ParkInfoView`, `GameInfoView`, and `ProfileView` are harder to review and modify;
- Profile Setup coordinates Storage and Postgres without a shared transaction;
- Realtime events trigger full reloads without batching or debounce;
- the app requires a network connection and has no offline cache;
- client/backend DTOs depend on string RPC names and JSON fields without code generation.

These are acceptable trade-offs for portfolio version 1.0. Further refactoring should not block completion unless it addresses a concrete defect.
