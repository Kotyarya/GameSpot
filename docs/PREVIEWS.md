# SwiftUI Preview inventory

The project includes a deterministic preview catalog for the user-facing SwiftUI surface. All `#Preview` declarations live in `PreviewSupport` and are split into small feature-based files, so Xcode Canvas never needs to display one oversized selector. Open the relevant `*Previews.swift` file in Xcode and show the Canvas. Every preview uses fixed local data; it does not require a signed-in Supabase session, location permission, Photos access, or network connectivity.

## Preview architecture

- `PreviewFixtures.swift` contains fixed users, profiles, sports, games, parks, statistics, weather, blocked users, and dates.
- Screen catalogs are grouped into app flow, main tabs, map, games, profile, and system-state files.
- Component catalogs are grouped into game, team, profile, and visual-component files; each catalog contains at most six previews.
- Preview services conform to the same small protocols as production services, but return local values and make no network calls or backend writes.
- Screen initializers accept ViewModels with production defaults. The app's runtime call sites therefore keep their existing behavior, while previews inject isolated dependencies.
- All preview-only fixtures, services, and catalogs are guarded by `#if DEBUG`; no secrets or production user data are included.

## User-facing screens

| Screen | Preview coverage |
| --- | --- |
| `RootView` | Signed-out root state |
| `AuthView` | Sign-in form |
| `PasswordResetRequestView` | Reset request form |
| `PasswordRecoveryView` | New-password form |
| `OnBoardingView` | First onboarding page |
| `ProfileSetupView` | Locally loaded sports |
| `MainTabView` | Complete tab shell with local dependencies |
| `MapView` | Loaded, empty, and error |
| `ParkInfoView` | Loaded park details |
| `GamesView` | Loaded, empty, and error |
| `CreateGameView` | Create form |
| `GameInfoView` | Loaded game, roster, weather, and block list |
| `JoinGameSheetView` | Joined-player team selection |
| `ProfileView` | Loaded and error |
| `PublicProfileView` | Loaded player profile |
| `SettingsView` | Settings list |
| `BlockedUsersView` | Loaded and empty |
| `PrivacyPolicyView` | Policy content |
| `ContentStateView` | Error and empty |
| `LoadingView` | Branded loading state |
| `NativeLoadingView` | Minimal native loading state |

## Reusable components

| Component | Preview coverage |
| --- | --- |
| `GameCard` | Upcoming and finished cards |
| `SportGlassPin` | Football map pin |
| `RankBadgesShowcaseView` | Full rank grid |
| `TeamSectionView` | Partially filled team |
| `PlayerSlotRow` | Current-player row |
| `EmptySlotRow` | Joinable slot |
| `ProfileAvatarView` | Local fallback avatar |
| `ProfileHeroView` | Hero composition |
| `ProfileSummaryCard` | Overall metrics |
| `ProfileSportStatsSection` | Multiple sports |
| `PatternBackground` | Repeating symbol pattern |
| `RecentMatchCard` | MVP match result |
| `MVPVoteRow` | Selected vote state |

## Intentional exclusions

- `RootAppContent` and `ReportUserSheet` are private implementation details and are exercised through their parent screens.
- `ContentStateUITestHarness` and `TeamActionUITestHarness` are UI-test-only harnesses, not product screens.
- Small private subviews declared inside screens are covered by the containing screen preview instead of receiving duplicate previews.

## Verification checklist

1. Select the `Game Spot` scheme and an iPhone simulator.
2. Open the `PreviewSupport` folder, choose the relevant feature catalog, and select a named preview in the Canvas.
3. Confirm loaded, empty, and error variants render without credentials or connectivity.
4. Run the Debug build to compile all preview macros and support code.
5. Run the Release build and the unit/UI test suites before merging preview changes.
