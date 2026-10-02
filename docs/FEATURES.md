# Implemented GameSpot Features

This document describes the current user journeys and the components behind them. It is not a roadmap.

## Authentication

### Sign Up

1. The user enters an email and password in `AuthView`.
2. `AuthViewModel` normalizes the email and calls `AuthService.signUp`.
3. Supabase Auth returns a user and, depending on confirmation settings, a session.
4. When a session exists, `SessionManager.refreshUser()` loads the profile.
5. Without a session, the UI displays Check Your Email and Resend actions.
6. `AuthLinkCoordinator` handles `gamespot://auth/confirmed`, exchanges the PKCE session, and reloads the profile.

Production currently auto-confirms email sign-up. The confirmation flow remains available for environments that require email verification.

### Sign In and Sign Out

Sign-in uses Supabase email/password Auth. `SessionManager` then selects onboarding, profile setup, or the main application from profile flags. Sign-out clears both Supabase and local state. Raw technical Auth errors are never shown to users.

Sign in with Apple is intentionally absent from version 1.0; the former non-functional button was removed.

### Password Recovery

1. Forgot Password opens `PasswordResetRequestView`.
2. `resetPasswordForEmail` sends a message with the `gamespot://auth/recovery` redirect.
3. The UI always displays a neutral response and does not reveal whether an email exists.
4. The deep link exchanges a temporary recovery session.
5. `PasswordRecoveryView` applies the same password rules as registration and updates Auth.
6. After success, the recovery session closes and the user returns to Sign In.

Both exact redirect URLs are configured in hosted Auth; wildcard redirects are not used.

## Onboarding and Profile Setup

A trigger creates the backend profile after the first sign-in.

1. `RootView` shows the carousel while `is_onboarded=false`.
2. Continue requests foreground location permission.
3. Completion updates `profiles.is_onboarded` and refreshes the session.
4. `is_profile_completed=false` opens Profile Setup.
5. The app loads sports, checks the username after a debounce, and accepts a favorite sport and optional photo.
6. The avatar is resized, compressed, and upserted to Storage.
7. Safe profile columns are updated; the session reloads only after complete success.

A partial avatar upload does not block retry because the same object path is replaced. Sport loading and submission have separate loading, error, and retry states.

## Map and Location

`MapViewModel` loads active `parks`. `MapView` displays MapKit markers and the current device location when permission is granted. Selecting a marker opens the park sheet.

Device location stays on the device and is not written to Supabase or sent to Open-Meteo. Open in Maps sends only the selected venue coordinates to Apple Maps.

Network failure and an empty park catalog use distinct states with a Try Again action where appropriate.

## Park Details and Discovery

The current product uses visual map selection rather than a separate text-search field. `ParkDetailsViewModel` loads the venue, supported sports, weekly hours, images, and aggregate rating in parallel.

The UI displays lighting, open/closed state, photos, rating, View Games, and Create Game. Requested-park protection prevents an older asynchronous response from overwriting a newer selection.

## Park Ratings

An authenticated user rates quality, facilities, and activity from 1 to 5. `rate_park` validates identity and range, inserts or updates the one review for that user and park, and rebuilds `parks_ratings`. The UI prevents double submission and keeps the form available for retry after failure.

## Create Game

1. The user selects Create Game from park details.
2. `CreateGameView` offers only sports linked to the park.
3. The user selects a sport and start time.
4. `CreateGameViewModel` validates the selection and calls `create_game`.
5. The server validates identity, future time, park/sport availability, and overlapping games.
6. Duration and capacity come from `sports`, not the client.
7. The game and creator membership in Team Alpha are created together.
8. Game Info opens after success.

The server is authoritative; direct table writes cannot replace the creator, duration, or capacity.

## Games List and My Games

`GamesView` supports two modes:

- `.myGames` calls `get_user_games()`;
- `.park(id)` calls `get_games_by_park(id)`.

`GameSectionBuilder` groups games by calendar day, sorts sections and games, and creates Today/Tomorrow/Yesterday or localized date labels. Tests can inject `Calendar`, current time, and `Locale`.

Realtime changes to `games` or `game_members` reload the active mode. Error and empty states are distinct: My Games suggests finding or creating a match, while a network error offers Retry.

## Game Information

`get_game_details` returns one composite payload containing match state, venue, sport, roster, current membership/vote, player highlights, and MVP. Weather loads in parallel after the details arrive.

Weather is optional: an Open-Meteo failure never hides match data. The user sees Refresh rather than false zero values. The screen derives Upcoming, Live, Voting, Finished, and Completed states from backend flags.

## Join and Leave

The team sheet lets the user select an available Team Alpha or Team Beta slot. A submitting state prevents repeated taps or dismissal. `join_game` locks the game row and validates pre-start state, duplicate membership, and team capacity. On success the app reloads details and closes the sheet; on failure it keeps the sheet open with a safe message.

`leave_game` follows the same pattern and removes only the current `auth.uid()` membership before the match starts. The creator may leave before the start without deleting the game.

## Match Lifecycle

Server cron jobs, not an open client timer, change state:

1. Scheduled — Join and Leave are available.
2. In Progress — starts on the first minute iteration after `starts_at`.
3. Finished — begins after the configured duration.
4. A match below `minimum_players_for_rewards` becomes Processed without rewards.
5. Otherwise participation rewards are granted once and MVP voting opens for three minutes.
6. The system selects the MVP, grants the bonus, and marks the match Processed.

The UI timer only presents time; changing the device clock cannot bypass backend rules.

## MVP Voting

Only participants may vote during the open window after a completed match. Self-votes, non-members, and duplicate votes are rejected. Casting a valid vote grants the voter two global performance points. The MVP receives global and per-sport bonuses based on vote count. The result is also stored in `game_members` for recent-match history.

## Reporting and Blocking

Selecting another player from Game Info opens a public profile with ratings, match count, Report User, and Block User.

Reports contain a reason and up to 500 characters of context. Resubmitting the same reason for the same user creates no duplicate and reveals no moderation state. Blocking requires confirmation. Blocked players remain visible in the match roster as anonymous, non-interactive rows so team capacity stays understandable, but they are excluded from social details, highlights, MVP voting, and the MVP card.

Profile → Blocked Users shows the private list and supports Unblock. Server-side username rules validate length, characters, reserved names, and a minimal offensive-word deny-list. Only privileged backend processes can read or change moderation status.

## Profile and Statistics

The profile loads in parallel:

- `profiles` with the favorite sport;
- all `user_sport_stats` rows;
- the three latest completed matches through RPC.

It displays global rating, games, MVP count, performance points, per-sport cards, Bronze-to-King league/division, and recent changes. Realtime updates profiles and statistics and reloads recent matches.

`RankHelper` calculates league/division in the client; only the backend changes numeric statistics.

## Avatar

Users can add, replace, or delete a photo during setup and from the completed profile. The client creates a JPEG no larger than 1024 px and 5 MiB, uploads it to `{userId}/avatar.jpg` with upsert, and adds a cache-busting query parameter. Storage policies restrict management to the owner folder.

The bucket is public for URL-based display. Anyone who knows the exact URL can technically download the image.

## Weather

`WeatherService` calls the free Open-Meteo forecast API with park coordinates and selects the hourly value nearest `starts_at`. It shows temperature, wind, and precipitation probability without an API key. The requested forecast covers seven days, so a distant game receives the closest available value; this is a known limitation.

## Realtime Updates

Realtime does not replace database reads. An event tells the ViewModel to reload authoritative state.

- game lists subscribe to `games` and `game_members`;
- game information subscribes to `games`, `game_members`, and `game_mvp_votes` filtered by game ID;
- profile subscribes to `profiles` and `user_sport_stats` filtered by user ID.

Channels are unique per screen instance and removed during cleanup, preventing earlier order-dependent failures.

## Privacy and Account Deletion

The Privacy Policy is available from Settings and publicly at <https://kotyarya.github.io/GameSpot/>. Settings provides irreversible account deletion with two confirmations.

The Edge Function verifies the JWT and removes the avatar, application data, and Auth user. On failure the app keeps the session and offers retry rather than pretending deletion succeeded. See [DATABASE.md](DATABASE.md) and [privacy-policy.md](privacy-policy.md).

## Intentionally Excluded from Version 1.0

- Sign in with Apple;
- push notifications;
- offline cache;
- payments, advertising, and analytics;
- background location;
- full text search for parks;
- administrative UI for parks and sports.

An omitted capability is not a defect when it is not promised in public product metadata.
