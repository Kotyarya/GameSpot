# Архитектура GameSpot

Снимок: ветка `codex/gamespot-appstore`, commit до документации `3452ed0`, 12 сентября 2026 года.

## Общая схема

GameSpot — feature-oriented SwiftUI-приложение с MVVM-подобным разделением. Отдельного repository/domain слоя нет: ViewModel обращается к узкому service protocol, production-реализация которого использует общий Supabase client или внешний HTTP API.

```text
SwiftUI View
    │ user action / .task / binding
    ▼
@MainActor ObservableObject ViewModel
    │ async/await через узкий protocol
    ▼
Service / Realtime service / Manager
    ├── Supabase Swift SDK ── Auth / PostgREST / RPC / Storage / Realtime
    ├── URLSession ───────── Open-Meteo
    └── CoreLocation ─────── foreground location on device
                               │
                               ▼
                    Supabase Postgres / Edge Function
```

Протоколы появились не как полноценный dependency container, а как минимальная seam для детерминированных tests. Production defaults по-прежнему используют `shared` services.

## Запуск приложения и глобальное состояние

`Game_SpotApp` создаёт три `@StateObject`:

- `SessionManager` — session, current user, profile и app state;
- `AppRouter` — selected tab и отдельные `NavigationPath` для Map/My Games;
- `AuthLinkCoordinator` — обработка auth/recovery deep links.

Они передаются через `environmentObject` в `RootView`.

`SessionManager.appState` — вычисляемый state machine:

```text
session not checked -> loading
no Auth user       -> auth
profile load error -> loadError + Retry
not onboarded      -> onboarding
profile incomplete -> profileSetup
ready              -> main
```

`RootView` отдаёт приоритет обработке auth link: пока ссылка обменивается на session показывается loader; recovery link открывает `PasswordRecoveryView`; затем выбирается экран по `SessionManager.appState`.

После sign out, успешного account deletion или завершения recovery `SessionManager` очищает user/profile и возвращает приложение в auth state. После обычного sign in/sign up вызывается `refreshUser()`, затем загружается `profiles`.

## Навигация

После входа `MainTabView` создаёт три вкладки:

- Map — отдельный `NavigationStack` и `mapPath`;
- My Games — отдельный `NavigationStack` и `gamesPath`;
- Profile — собственный `NavigationStack`; Settings и его дочерние экраны открываются локальными `NavigationLink`, без маршрутов в `AppRouter`.

Typed `Route` поддерживает:

- `.myGames`;
- `.parkGames(id:name:)`;
- `.game(UUID)`;
- `.createGame(park:sports:)`.

Функция `destination(_:)` строит конечный экран. Profile-навигация к `SettingsView`, Privacy Policy и Blocked Users создаётся локально.

## Слои и ответственность

### Views

Views отвечают за layout, presentation state, navigation и отправку действий в ViewModel. Значимая бизнес-валидация должна находиться в ViewModel/backend, но в больших views остаётся часть presentation logic: статус парка, countdown, видимость actions и форматирование.

Основные экраны:

| Экран | Назначение |
| --- | --- |
| `AuthView` | sign in, sign up, confirmation/resend, переход к reset request |
| `OnBoardingView` | вводный carousel и foreground location permission |
| `ProfileSetupView` | username, favorite sport, optional avatar |
| `MapView` | карта активных парков и выбор маркера |
| `ParkInfoView` | данные площадки, рейтинг, игры и create action |
| `GamesView` | игры пользователя или выбранного парка |
| `CreateGameView` | sport/time и создание игры |
| `GameInfoView` | состав команд, weather, Join/Leave, MVP и состояния матча; заблокированные участники остаются в roster как анонимные non-interactive rows, но исключаются из social detail |
| `JoinGameSheetView` | выбор команды или выход из матча |
| `ProfileView` / `PublicProfileView` | общие hero/summary/per-sport components; собственный профиль добавляет Edit/avatar actions, публичный — Report/Block |
| `SettingsView` | Privacy Policy, Blocked Users, support/about, sign out и удаление аккаунта с системными confirmations |
| `PasswordResetRequestView` | запрос recovery email |
| `PasswordRecoveryView` | новый пароль по deep link |

`ContentStateView` — единое production-представление error/empty/retry. `LoadingView` — полноэкранная загрузка.

### ViewModels

| ViewModel | Основная ответственность | Зависимости |
| --- | --- | --- |
| `AuthViewModel` | нормализация email, sign in/up, confirmation state | `AuthServing` |
| `ProfileSetupViewModel` | загрузка sports, debounce username, avatar + profile transaction at client level | `ProfileSetupServing`, `SportFetching`, `AvatarStoring` |
| `MapViewModel` | список активных парков и load error | `ParksFetching` |
| `ParkDetailsViewModel` | параллельная загрузка деталей, rating state, stale-response protection | `ParkDetailsServing` |
| `GamesViewModel` | режим My Games/Park, sections source data, Realtime reload | `GamesFetching`, `GamesRealtimeSubscribing` |
| `CreateGameViewModel` | client validation sport и create RPC | `GameCreating` |
| `GameInfoViewModel` | details, optional weather, Join/Leave/Vote, Realtime | `GameInfoServing`, `WeatherFetching`, `GameInfoRealtimeSubscribing` |
| `ProfileViewModel` | profile/stats/recent matches, avatar actions, Realtime | `ProfileFetching`, `ProfileRealtimeSubscribing`, avatar protocols |
| `PublicProfileViewModel` | read-only profile и per-sport stats другого игрока | `ProfileFetching` |
| `AccountDeletionViewModel` | single-flight delete и user-safe error | `AccountDeleting` |
| `PasswordResetRequestViewModel` | neutral recovery request result | `PasswordRecoveryServing` |
| `PasswordRecoveryViewModel` | password policy + update | `PasswordRecoveryServing` |

Все ViewModel выполняются на `@MainActor`, поэтому `@Published` state меняется последовательно на UI actor.

### Services и managers

| Компонент | Ответственность |
| --- | --- |
| `SupabaseService` | единственный `SupabaseClient`, Auth redirect и publishable configuration |
| `AuthService` | email/password Auth, resend, recovery, PKCE session exchange |
| `ProfileService` | profile, per-sport stats, recent matches, onboarding/profile flags |
| `GameService` | client-facing game RPC |
| `ParkService` | прямые catalogue reads и rating RPC |
| `SportService` | sports catalogue |
| `SupabaseAvatarStorageService` | `{userId}/avatar.jpg`, upsert/remove/public URL |
| `AccountDeletionService` | JWT-authenticated DELETE Edge Function invocation |
| `WeatherService` | Open-Meteo hourly forecast и выбор ближайшего часа |
| `LocationManager` | when-in-use permission и Core Location updates |
| Realtime services | lifecycle конкретного channel и callbacks для reload |

`AppConfiguration` читает `SupabaseURL` и `SupabasePublishableKey` из bundle Info.plist и останавливает запуск при отсутствующем/невалидном значении. Service-role key в iOS не используется.

## Модели

`Decodable` модели отражают table/RPC payloads и используют `CodingKeys` для snake_case:

- `Park`, `ParkDetails`, `ParkHour`, `ParkImage`, `ParkRating`, `ParkShort`;
- `Sport`, `SportType`;
- `Game`, `GameDetails`, `MVPPlayer`;
- `Profile`, `Player`, `RecentMatch`;
- `UserSportStats`;
- `Weather` и transport DTO Open-Meteo.

`Team` строго соответствует Postgres enum: `Team Alpha`, `Team Beta`.

## Главные цепочки данных

### Карта и площадка

```text
MapView
  -> MapViewModel.load
  -> ParkService.fetchParks
  -> SELECT public.parks WHERE is_active = true

ParkInfoView
  -> ParkDetailsViewModel.load
  -> ParkService.fetchParkDetails
  -> parallel SELECT parks / parks_sports+sports / parks_hour /
                     parks_images / parks_ratings
```

GPS-координаты показываются MapKit на устройстве. Они не передаются в Supabase.

### Игры

```text
GamesView
  -> GamesViewModel.load
  -> GameService.get_user_games OR get_games_by_park RPC
  -> [Game]
  -> GameSectionBuilder(Calendar, now, Locale)

CreateGameView
  -> CreateGameViewModel
  -> create_game RPC
  -> games + creator membership in one server function
```

### Детали, команды и MVP

```text
GameInfoView
  -> GameInfoViewModel.load
  -> get_game_details RPC -> GameDetails
  -> Open-Meteo -> optional Weather

JoinGameSheetView
  -> GameInfoViewModel.joinGame/leaveGame
  -> server RPC
  -> get_game_details reload

MVPVoteRow
  -> GameInfoViewModel.submitVote
  -> vote_mvp RPC
  -> Realtime event -> details reload
```

Backend, а не UI, является источником истины для времени, вместимости, участия, голосования и наград.

### Профиль и avatar

```text
ProfileView
  -> ProfileViewModel.load
  -> parallel ProfileService: profiles / user_sport_stats / get_recent_matches

selected UIImage
  -> AvatarImageEncoder (max 1024 px, JPEG <= 5 MiB)
  -> Storage upsert {userId}/avatar.jpg
  -> ProfileService.updateAvatar
  -> local model update + Realtime
```

Profile Setup выполняет те же операции последовательно. Это не единая database transaction: если Storage succeeded, а profile update упал, retry безопасен благодаря upsert.

### Удаление аккаунта

```text
ProfileView -> SettingsView -> AccountDeletionViewModel
  -> AccountDeletionService DELETE /functions/v1/delete-account
  -> gateway verifies JWT
  -> remove avatar
  -> service-role delete_user_data(user from claims)
  -> Auth admin deleteUser
  -> client clears local session only after deleted=true
```

## Realtime

Клиент использует Postgres Changes, а payload обычно служит сигналом перечитать authoritative RPC/table result.

| Контекст | Tables | Фильтр/реакция |
| --- | --- | --- |
| Games list | `games`, `game_members` | AnyAction, затем reload текущего режима |
| Game details | `games`, `game_members`, `game_mvp_votes` | по `gameId`, затем details reload |
| Profile | `profiles`, `user_sport_stats` | по `userId`; profile decode или stats/recent reload |

Каждый экземпляр получает уникальный channel. Handlers регистрируются до `subscribeWithError()`. `deinit` вызывает `unsubscribe`, отменяет subscriptions и удаляет channel из client.

## Где живёт бизнес-логика

- security, ownership, capacity, time, lifecycle, rewards, rating aggregation и deletion — PostgreSQL functions/RLS/grants/Edge Function;
- orchestration запросов и user-safe UI state — ViewModels;
- image preparation, date grouping и password rules — небольшие production helpers;
- layout/formatting/countdown/open-hours presentation — SwiftUI views и helpers.

Подробности backend: [DATABASE.md](DATABASE.md). Пользовательские сценарии: [FEATURES.md](FEATURES.md).

## Известные архитектурные ограничения

- production dependencies создаются через singleton defaults, полноценного composition root нет;
- крупные SwiftUI files (`ParkInfoView`, `GameInfoView`, `ProfileView`) трудно изменять и review;
- `ProfileSetup` координирует Storage и Postgres без общей транзакции;
- Realtime событие вызывает полный reload, без batching/debounce;
- app требует сеть и не имеет offline cache;
- client/backend DTO связаны строковыми именами RPC и JSON полями без code generation.

Для портфолио 1.0 это допустимые компромиссы; дальнейший рефакторинг не должен блокировать публикацию без конкретного дефекта.
