# Game Spot

A native iOS application that helps players discover sports venues, join or create matches, track competitive rankings, and participate in post-game MVP voting — all backed by a live Supabase backend.

---

## Overview

**Game Spot** is a SwiftUI sports matchmaking application designed to help users organize amateur sports events, discover sports venues, and participate in local games through a modern mobile experience.

The app connects amateur and recreational players with local games at sports parks, supports team-based match participation, and provides player statistics, league rankings, and real-time match updates.

---

## Features

The following capabilities are **implemented in the current codebase**:

### Authentication & Onboarding

- Email/password **sign in** and **sign up** via Supabase Auth (`AuthService`, `AuthView`).
- **Sign in with Apple** UI is present but currently **disabled** in `AuthView`.
- Multi-step **onboarding** carousel with location permission request (`OnBoardingView`).
- **Profile setup** flow: avatar upload (Supabase Storage), username availability check, favorite sport selection (`ProfileSetupView`).

### User Profiles

- Global and per-sport **ratings**, match count, MVP count, and performance points (`Profile`, `UserSportStats`).
- **League-style rank** display (Bronze → King with divisions) via `RankHelper`.
- **Recent matches** list with rating/points earned and MVP highlights (`RecentMatchCard`).
- **Sign out** from the profile tab.

### Sports & Matches

- Supported sport types in the client: **football**, **basketball**, **volleyball** (`SportType`).
- **Create game** at a selected park with sport and start time (`CreateGameView`).
- **My Games** list grouped by date (`GamesView`).
- **Park-specific game lists** navigable from the map sheet.
- **Game details** screen with teams, player highlights, park info, and weather.
- **Join / leave** games with **Team Alpha** and **Team Beta** assignment (`JoinGameSheetView`).
- Live / open / full / finished **game state** on cards and detail views (`GameCard`, `GameInfoView`).
- **Countdown timer** and live indicator for in-progress or upcoming games (`TimelineView`).

### Maps & Geolocation

- **MapKit** map with park markers and user location controls (`MapView`).
- **Bottom sheet** park details with photos, sports, hours, ratings, and actions (`ParkInfoView`).
- **Open in Maps** for directions to a park.
- **Location permission** requested during onboarding (`LocationManager`); coordinates are not consumed elsewhere in the app yet.

### MVP Voting

- Post-match **MVP voting** when `mvpVotingOpen` is true (`GameInfoView`, `MVPVoteRow`).
- Vote submission via Supabase RPC `vote_mvp`.
- Display of **match MVP** after processing (`mvpPlayer`).

### Rankings & Leagues

- Six leagues: Bronze, Silver, Gold, Diamond, Ruby, King (`RankLeague`).
- Five divisions per league (I–V) based on rating thresholds (`RankHelper`).
- Rank-colored UI assets under `Assets.xcassets/Ranks/`.

### Parks

- Fetch active parks and detailed park data (hours, images, sports, ratings).
- **Rate a park** on quality, facilities, and activity (1–5 stars) via RPC `rate_park`.
- Open/closed status derived from weekly hours in the UI.

### Weather

- Hourly **weather forecast** for game time via [Open-Meteo](https://open-meteo.com/) (`WeatherService`).
- Temperature, wind speed, and precipitation probability on the game detail screen.

### Real-Time Synchronization

Supabase Realtime (`realtimeV2`) subscriptions update:

| Screen | Tables |
|--------|--------|
| Games list | `games`, `game_members` |
| Game details | `games`, `game_members`, `game_mvp_votes` |
| Profile | `profiles`, `user_sport_stats` |

### UI & Platform

- **SwiftUI** with **glassEffect** styling (iOS 26 Liquid Glass APIs).
- Custom loading screen, reusable `GameCard`, `SportGlassPin`, and rank-themed profile header.
- Portrait orientation on iPhone; portrait (+ upside-down) on iPad.

---

## Screenshots

> Add screenshots to `docs/screenshots/` and replace the placeholders below.

| Screen | Description |
|--------|-------------|
| ![Auth](docs/screenshots/auth.png) | Authentication — *placeholder* |
| ![Map](docs/screenshots/map.png) | Park map & bottom sheet — *placeholder* |
| ![Games](docs/screenshots/games.png) | My Games list — *placeholder* |
| ![Game Detail](docs/screenshots/game-detail.png) | Game details, teams & countdown — *placeholder* |
| ![Profile](docs/screenshots/profile.png) | Profile, ranks & stats — *placeholder* |
| ![Onboarding](docs/screenshots/onboarding.png) | Onboarding flow — *placeholder* |

---

## Architecture

The project follows a **feature-oriented MVVM** structure with a shared service layer and global app state.

```
┌─────────────────────────────────────────────────────────┐
│                      SwiftUI Views                       │
│   AuthView · MapView · GamesView · GameInfoView · …     │
└─────────────────────────┬───────────────────────────────┘
                          │ @StateObject / @ObservedObject
┌─────────────────────────▼───────────────────────────────┐
│                    ViewModels (@MainActor)                │
│  AuthViewModel · GamesViewModel · GameInfoViewModel · …   │
└─────────────────────────┬───────────────────────────────┘
                          │ async/await
┌─────────────────────────▼───────────────────────────────┐
│              Services (singleton, Sendable)               │
│  AuthService · GameService · ParkService · ProfileService │
│  WeatherService · SportService · SupabaseService          │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│           Supabase (Auth · Postgres · RPC · Storage ·     │
│           Realtime)  +  Open-Meteo HTTP API               │
└─────────────────────────────────────────────────────────┘
```

### MVVM

- **Views** render UI and forward user actions.
- **ViewModels** (`@MainActor`, `ObservableObject`) hold `@Published` state and orchestrate async work.
- **Models** are `Decodable` structs mapping to Supabase tables/RPC responses.

### Services Layer

Each domain has a dedicated service class using `SupabaseService.shared.client`:

| Service | Responsibility |
|---------|----------------|
| `AuthService` | Sign up, sign in, sign out, Apple OAuth |
| `ProfileService` | Profiles, stats, recent matches, onboarding |
| `GameService` | CRUD-style game operations via RPCs |
| `ParkService` | Parks, hours, images, ratings |
| `SportService` | Sports catalog |
| `WeatherService` | Open-Meteo forecast lookup |

### App State & Navigation

- **`SessionManager`** — global auth/profile state machine (`AppState`: auth, loading, onboarding, profileSetup, main).
- **`AppRouter`** — tab selection and per-tab `NavigationPath` for typed `Route` destinations.
- Injected via `@EnvironmentObject` from `Game_SpotApp`.

### Data Flow

1. View triggers `.task` or button action.
2. ViewModel calls a Service method with `async/await`.
3. Service queries Supabase (table select, RPC, or storage upload).
4. ViewModel updates `@Published` properties on the main actor.
5. Realtime listeners trigger silent reloads where configured.

---

## Technologies

| Category | Technology | Version / Notes |
|----------|------------|-----------------|
| Language | Swift | 6.0 (app target) |
| UI | SwiftUI | iOS 26 APIs (`glassEffect`, modern MapKit) |
| Architecture | MVVM | Feature modules + service layer |
| Backend | [Supabase](https://supabase.com/) | `supabase-swift` **2.44.1** |
| Auth | Supabase Auth | Email/password; Apple OAuth stub |
| Database | Supabase Postgres | Tables + RPC functions |
| Realtime | Supabase Realtime V2 | Postgres change subscriptions |
| Storage | Supabase Storage | `avatars` bucket |
| Maps | MapKit | Markers, user location, directions |
| Weather | Open-Meteo REST API | Hourly forecast |
| Concurrency | Swift Concurrency | `async/await`, `@MainActor` |
| Testing | XCTest | Unit + UI test targets |
| IDE | Xcode | **26.4.1** (project setting) |
| Min. deployment | iOS | **26.0** |

---

## Project Structure

```
Game Spot/
├── App.swift                    # @main entry, environment setup
├── RootView.swift               # App-state router (auth → main)
├── AppState/
│   ├── SessionManager.swift     # Session & profile state machine
│   └── AppRouter.swift          # Tab + NavigationPath routing
├── Core/
│   ├── Models/                  # Game, Profile, Park, Sport, Weather, …
│   ├── Services/                # Supabase & weather API layer
│   └── Managers/
│       └── LocationManager.swift
├── Features/
│   ├── Auth/                    # Login & registration
│   ├── OnBoarding/              # First-run carousel
│   ├── ProfileSetup/            # Avatar, username, favorite sport
│   ├── MainTabView/             # Map · My Games · Profile tabs
│   ├── Map/                     # Map screen + park markers
│   ├── ParkInfo/                # Park bottom sheet
│   ├── Games/                   # Game lists
│   ├── GameInfo/                # Game detail, MVP, weather
│   ├── CreateGame/              # Game creation flow
│   ├── JoinGame/                # Team join/leave sheet
│   ├── Profile/                 # User profile & stats
│   └── Progress/                # LoadingView
├── UI/                          # Reusable components (GameCard, SportGlassPin)
├── Helpers/                     # RankHelper, formatters
└── Assets.xcassets/             # Colors, rank themes, onboarding images

Game SpotTests/                  # Unit & ViewModel tests
Game SpotUITests/                # UI automation tests
```

---

## Package Contents

The repository contains all components required to build and run the application:

- Complete iOS source code written in Swift and SwiftUI
- ViewModels implementing the MVVM architecture
- Service layer responsible for communication with Supabase
- Database models and DTO structures
- Application assets, icons, and onboarding resources
- Unit and UI test suites
- Xcode project configuration files

The project represents the complete source code of the Game Spot application and is intended for educational and development purposes.

---

## Database

The iOS client does not ship SQL migrations; the schema is inferred from service calls and models. The backend is a **Supabase Postgres** project.

### Tables (referenced in code)

| Table | Purpose |
|-------|---------|
| `profiles` | User profile, rating, stats flags, favorite sport |
| `user_sport_stats` | Per-sport rating and match statistics |
| `sports` | Sport catalog |
| `parks` | Venue name, coordinates, address, lighting |
| `parks_hour` | Weekly opening hours |
| `parks_images` | Park photo URLs |
| `parks_sports` | Sports available at each park |
| `parks_ratings` | Aggregated park rating averages |
| `games` | Match schedule and status fields |
| `game_members` | Players assigned to teams |
| `game_mvp_votes` | MVP vote records |

### RPC Functions

| RPC | Used by |
|-----|---------|
| `get_games_by_park` | `GameService.fetchGamesByPark` |
| `get_user_games` | `GameService.fetchUserGames` |
| `get_game_details` | `GameService.fetchGameDetails` |
| `create_game` | `GameService.createGame` |
| `join_game` | `GameService.joinGame` |
| `leave_game` | `GameService.leaveGame` |
| `vote_mvp` | `GameService.voteMVP` |
| `get_recent_matches` | `ProfileService.getRecentMatches` |
| `rate_park` | `ParkService.ratePark` |
| `has_user_rated` | `ParkService.hasUserRated` |

### Storage

| Bucket | Path pattern | Purpose |
|--------|--------------|---------|
| `avatars` | `{userId}/avatar.jpg` | Profile avatar upload |

### Key Model Entities

- **`Game`** — schedule, capacity, live/finished flags, joined player count.
- **`GameDetails`** — full roster, park summary, MVP state, vote status.
- **`Profile`** — username, avatar, global rating, onboarding flags.
- **`Player`** — team assignment, rank badges, MVP vote counts.
- **`Park` / `ParkDetails`** — location, hours, images, sports, ratings.
- **`Team`** — `Team Alpha` / `Team Beta` (string-backed enum).

---

## Installation

### Prerequisites

1. **macOS** with **Xcode 26.4+** installed.
2. An **Apple Developer** team configured in Xcode (project uses automatic signing).
3. A **Supabase project** with the tables, RPCs, RLS policies, and storage bucket matching the client expectations.
4. Active **internet connection** (Supabase + Open-Meteo).

### Steps

```bash
# 1. Clone the repository
git clone <repository-url>
cd "Game Spot"

# 2. Open the Xcode project
open "Game Spot.xcodeproj"
```

3. Wait for Swift Package Manager to resolve **supabase-swift** (declared in the project).
4. Configure Supabase credentials in `Game Spot/Core/Services/SupabaseService.swift`:
   - `supabaseURL`
   - `supabaseKey` (publishable/anon key)
5. Select the **Game Spot** scheme and an **iOS 26** simulator or device.
6. Build and run (`⌘R`).

### Running Tests

```bash
# Unit tests
xcodebuild test \
  -scheme "Game Spot" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing:"Game SpotTests"

# UI tests
xcodebuild test \
  -scheme "Game Spot" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing:"Game SpotUITests"
```

Or use **Product → Test** (`⌘U`) in Xcode.

---

## Requirements

| Requirement | Detail |
|-------------|--------|
| **Operating system** | iOS **26.0+** |
| **Devices** | iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`) |
| **Xcode** | 26.4.1 (as recorded in project metadata) |
| **Swift** | 6.0 (application target) |
| **Internet** | Required for auth, data, realtime, weather |
| **Supabase** | Project with matching schema, Auth, Storage, Realtime enabled |
| **Simulator / device** | iOS 26 SDK |
| **Orientation** | Portrait (iPhone); portrait on iPad |

---

## Testing

The project includes **XCTest** unit tests, ViewModel tests, and basic UI tests.

### Unit Tests (`Game SpotTests/Unit/`)

| File | Coverage |
|------|----------|
| `RankHelperTests` | League & division calculation |
| `NumberFormatterHelperTests` | K/M/B rating formatting |
| `FormatTimeTests` | Park hours time formatting |
| `SportModelTests` | Sport type → SF Symbol mapping |
| `GameModelDecodingTests` | JSON decoding, `GamesMode` equality |
| `GameStateLogicTests` | Live state, card status, countdown, teams |
| `AuthValidationTests` | `AuthViewModel.isValid`, sign-up password rules |
| `ParkHoursLogicTests` | Park open/closed logic |
| `SessionManagerAppStateTests` | `AppState` transitions |

### ViewModel Tests (`Game SpotTests/ViewModels/`)

| File | Coverage |
|------|----------|
| `AuthViewModelTests` | Validation & initial state |
| `GamesViewModelTests` | Loading lifecycle |
| `GameInfoViewModelTests` | MVP vote guards, load state |
| `ProfileViewModelTests` | Initial state, load behavior |
| `CreateGameViewModelTests` | Sport validation before create |

### UI Tests (`Game SpotUITests/`)

| File | Coverage |
|------|----------|
| `Game_SpotUITests` | Launch smoke test |
| `AuthFlowUITests` | Sign In UI, sign-up mode switch, email input |
| `NavigationFlowUITests` | Tab bar navigation when authenticated |
| `Game_SpotUITestsLaunchTests` | Launch performance metric |

### Test Support

- `TestFixtures.swift` — JSON factory helpers for models.
- `GameSpotLogic.swift` — mirrors view-embedded game logic for regression testing.
- `AuthValidationLogic.swift` / `ParkHoursLogic.swift` — mirrors UI validation rules.

> Some ViewModel tests call the live Supabase backend and require network access and valid credentials.

---

## Known Limitations

The current version of the application has several limitations:

- The application requires an active internet connection.
- Sign in with Apple functionality has been implemented but is not currently enabled.
- The application does not support offline mode.
- Some features depending on maps and geolocation may increase battery consumption.
- Performance may vary depending on network quality and backend availability.
- The current version has not yet been published in the App Store and remains in the testing phase.

---

## Future Improvements

Possible future development directions include:

1. Full support for Sign in with Apple authentication.
2. Offline mode with local data caching.
3. Push notifications for upcoming matches and MVP voting.
4. Enhanced geolocation features and nearby venue recommendations.
5. Expanded statistics and player performance analytics.
6. Additional sports categories and event types.
7. Improved accessibility support and interface customization.
8. Further optimization of network communication and battery consumption.

---

## Author

Game Spot was developed as part of an engineering diploma project focused on modern mobile application development using SwiftUI, Supabase, PostgreSQL, and MapKit.

The project demonstrates the design, implementation, and testing of a complete mobile system supporting the organization of amateur sports events.

---

## Repository

Source code repository:

https://github.com/Kotyarya/GameSpot

The repository contains the complete source code, project configuration files, assets, and test suites required to build and run the application.
