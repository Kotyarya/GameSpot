# Game Spot

Game Spot — нативное iOS-приложение для поиска спортивных площадок, создания любительских матчей, выбора команды, отслеживания рейтинга и голосования за MVP. Проект готовится к App Store как portfolio application, а не как развиваемый startup.

## Что умеет приложение

- email/password registration, sign in и password recovery;
- onboarding, foreground location permission и настройка профиля;
- MapKit-карта активных площадок и подробности park;
- создание игры, My Games, Join/Leave Team Alpha или Team Beta;
- server-driven lifecycle матча и трёхминутное MVP voting;
- global/per-sport statistics и league ranks Bronze → King;
- Realtime updates игр, участников, голосов и профиля;
- avatar add/replace/remove через Supabase Storage;
- weather игры через Open-Meteo;
- park rating;
- Privacy Policy внутри приложения;
- необратимое удаление аккаунта и связанных данных.

Версия 1.0 намеренно не содержит Sign in with Apple, payments, ads, analytics, offline mode, push notifications и background location.

## Стек

| Область | Технология |
| --- | --- |
| Client | Swift 6, SwiftUI, Swift Concurrency |
| Platform | iOS 26+, MapKit, Core Location, PhotosUI |
| Backend | Supabase Auth, Postgres, RPC, RLS, Realtime, Storage, Edge Functions |
| Dependency | `supabase-swift` 2.44.1 (Swift Package Manager) |
| Scheduling | `pg_cron` |
| Weather | Open-Meteo REST API |
| Tests | XCTest/XCUITest + SQL regression scripts |

## Архитектура

```text
SwiftUI Views
      ↓
@MainActor ViewModels
      ↓
Service protocols / Services / Realtime services
      ↓
Supabase Swift SDK или URLSession/CoreLocation
      ↓
Supabase Postgres/Auth/Storage/Edge Function + Open-Meteo
```

PostgreSQL является источником истины для ownership, capacity, match state, MVP и rewards. Client ViewModels отвечают за orchestration и понятное UI-state. Realtime event обычно инвалидирует данные и запускает повторный authoritative query.

Подробно: [архитектура](docs/ARCHITECTURE.md), [backend](docs/DATABASE.md), [функции](docs/FEATURES.md).

## Быстрый запуск

Требуются Xcode 26.4+, iOS 26 Simulator и internet.

```bash
git clone https://github.com/Kotyarya/GameSpot.git
cd GameSpot
git switch codex/gamespot-appstore
open "Game Spot.xcodeproj"
```

Выберите scheme `Game Spot` и iOS 26 Simulator. Swift Package Manager автоматически разрешит зависимости.

Client configuration читается из `Game-Spot-Info.plist` по ключам `SupabaseURL` и `SupabasePublishableKey`. В iOS запрещено добавлять service-role key, database password или другой server secret.

Полная инструкция нового Mac, Simulator/device, tests и локального Supabase: [SETUP.md](docs/SETUP.md).

## Проверка

Unit tests:

```bash
xcodebuild test \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:'Game SpotTests'
```

Release Simulator build:

```bash
xcodebuild build \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Backend clean reset:

```bash
supabase start
supabase db reset --local --no-seed
```

Database regression scripts находятся в `supabase/tests/database/`. Hosted production нельзя сбрасывать.

## Структура

```text
Game Spot/
├── App.swift, RootView.swift
├── AppState/                 # session state machine и navigation
├── Core/
│   ├── Models/
│   ├── Services/
│   └── Managers/
├── Features/                 # Auth, Map, Games, Profile и другие screens
├── UI/                       # общие visual components
└── Helpers/

Game SpotTests/               # unit и ViewModel tests
Game SpotUITests/             # UI tests и reviewer journeys
supabase/
├── migrations/               # воспроизводимая schema + security/lifecycle fixes
├── functions/delete-account/ # JWT-protected account deletion
├── tests/database/           # SQL regression suite
└── config.toml               # local Supabase configuration
docs/                         # техническая и release документация
```

## Документация

- [Что изменилось после версии владельца](docs/CHANGES_SINCE_USER_VERSION.md)
- [Архитектура](docs/ARCHITECTURE.md)
- [Supabase database/backend](docs/DATABASE.md)
- [Пользовательские сценарии](docs/FEATURES.md)
- [Запуск и тестирование](docs/SETUP.md)
- [Архитектурные решения](docs/DECISIONS.md)
- [Текущее состояние и следующие шаги](docs/TODO.md)
- [Privacy Policy source](docs/privacy-policy.md)
- [App Store privacy checklist](docs/app-store-privacy.md)

## Текущий release status

Основные security, lifecycle, account deletion, UI-state и test tasks завершены. До App Store остаются hosted password-recovery configuration/E2E, report/block flow, App Store Connect privacy metadata, screenshots, signing и TestFlight. Актуальная точка возврата — [TODO.md](docs/TODO.md); scope и progress отслеживаются в Notion epic TASK-56.

Public Privacy Policy: <https://kotyarya.github.io/GameSpot/>

Support: `gamespot.support@icloud.com`

## Git workflow

Текущая рабочая ветка — `codex/gamespot-appstore`. Не commit в `main`, не push/merge и не изменять production Supabase без явного решения владельца. Backend changes оформлять только forward migrations; секреты и production user data не коммитить.

## Автор

Game Spot создан Максимом Аксамитным как дипломный и portfolio iOS-проект. Последующая release-hardening работа задокументирована в [CHANGES_SINCE_USER_VERSION.md](docs/CHANGES_SINCE_USER_VERSION.md).
