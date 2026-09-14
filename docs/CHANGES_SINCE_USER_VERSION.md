# Что изменилось после исходной версии GameSpot

Снимок документа: 12 сентября 2026 года.

Этот файл отвечает на вопрос: «что изменилось по сравнению с версией, которую сделал владелец проекта». За исходную точку принят commit `369ce9cc08c9107a4d42d166f0de9059a4537c97` (`README`, 9 июня 2026 года). Текущая документируемая точка до TASK-55 — `3452ed04975a2aa8dd4f02055da7782613a171a5` в ветке `codex/gamespot-appstore`.

Диапазон `369ce9c..3452ed0` содержит 95 изменённых файлов, 11 233 добавленные и 1 047 удалённых строки. Это не обычный changelog релизов: ниже описаны код, Supabase, тесты, внешние настройки и состояние задач Notion.

## Краткий итог

Исходное приложение уже содержало основной продукт: SwiftUI-интерфейс, карту парков, игры, команды, профиль, рейтинг, MVP и подключение к вручную настроенному Supabase. Работа после `369ce9c` была сосредоточена на подготовке портфолио-релиза:

- backend перенесён в versioned migrations и применён к production без пересоздания данных;
- закрыты обходы RLS, лишние RPC-права и изменение статистики клиентом;
- исправлен жизненный цикл матча и MVP;
- добавлены удаление аккаунта, privacy-материалы и password recovery;
- устранены нестабильные Join/Leave, avatar upload и date grouping;
- основные ViewModel отделены от live backend в unit-тестах;
- добавлены понятные loading/error/empty/retry состояния;
- подтверждены Release-сборки, SQL regression suite и реальный authenticated UI-путь.

## Не относящееся к продуктовой функции

### Рабочее соглашение

Commit `5168dff` добавил `AGENTS.md`: правила ветки, Notion-процесса, безопасной работы с production Supabase и границы App Store. Файл не попадает в приложение и не меняет runtime.

## Изменения по задачам

### TASK-19 — версионирование Supabase

До изменения backend существовал только как ручное состояние production, а remote migration history была пустой.

Сделано:

- добавлен `supabase/config.toml` для локального стека Postgres 17, Auth, Realtime и Storage;
- создана baseline migration со схемой, индексами, RPC, triggers, RLS, grants, Storage, Realtime publication и cron;
- debug RPC с зашитыми тестовыми UUID намеренно не перенесены и удаляются отдельной migration;
- добавлены шесть SQL regression scripts;
- задокументированы `supabase start`, `supabase db reset` и запуск SQL-тестов.

Production: существующая схема была зарегистрирована validation-only baseline, затем применены follow-up migrations. Remote history сейчас содержит 9 записей. Baseline нельзя повторно выполнять поверх существующего production.

Проверка: clean local reset, 6/6 SQL tests, `supabase db diff` без расхождений. Commits: `6166c8d`, `b173cc1`. Статус Notion: Готово.

### TASK-11 — закрытие привилегированных RPC

До изменения `anon` мог выполнять изменяющие данные `SECURITY DEFINER` функции, включая debug и lifecycle RPC.

Сделано:

- отозван default/public/anon execute;
- `authenticated` оставлены только необходимые клиентские RPC;
- `start_games`, `finish_games`, `open_mvp_voting`, `process_finished_games` и `delete_user_data` оставлены владельцу/service role;
- read RPC переведены на `SECURITY INVOKER`;
- всем прикладным функциям установлен фиксированный `search_path`;
- hosted helper `rls_auto_enable()` дополнительно закрыт для client roles.

Production: применено и проверено негативными вызовами внутри rollback-транзакций. Commit: `7124ce5`; дополнительное ограничение — `91e38d5`. Статус: Готово.

### TASK-12 — least-privilege таблиц и RLS

До изменения несколько write policies использовали безусловные `true`, поэтому авторизованный клиент мог обходить бизнес-RPC.

Сделано:

- у `anon` и `authenticated` отозваны прямые writes для игр, участников, голосов, отзывов, агрегатов и статистики;
- `anon` оставлено чтение статического каталога парков и спорта;
- `authenticated` оставлены чтения для интерфейса и Realtime;
- бизнес-изменения маршрутизированы через RPC;
- для `profiles` UPDATE ограничен безопасными колонками и собственной строкой.

Production: применено; spoofed identifiers и прямые writes отклоняются. Commit: `5008a6a`. Статус: Готово.

### TASK-57 — запрет изменения статистики клиентом

Задача закрыта реализацией TASK-12 и TASK-13, поэтому отдельной дублирующей migration нет.

Клиент может изменять только `username`, `avatar_url`, `favorite_sport_id`, `is_onboarded`, `is_profile_completed`. `rating`, `games_played`, `mvp_count`, `perf_points` меняют только доверенные lifecycle RPC. Проверено на production. Связанные commits: `5008a6a`, `4c56097`. Статус: Готово.

### TASK-13 — жизненный цикл матча и MVP

До изменения голосование могло открыться через 20 секунд после старта, а `vote_mvp` одновременно запрещал голосовать для завершённой игры. Join/Leave недостаточно учитывали состояние.

Новый серверный автомат:

```text
scheduled -> in progress -> finished + MVP voting -> processed
                                  \-> processed без наград при нехватке игроков
```

Сделано:

- `create_game` запрещает прошлое время, неизвестный sport/park и пересечение слотов;
- создатель добавляется в Team Alpha, но больше не получает очки только за создание;
- `join_game` и `leave_game` блокируют строку и разрешены только до старта;
- cron переводит игру между состояниями каждую минуту;
- участие награждается один раз только при достаточном количестве игроков;
- MVP window длится 3 минуты после фактического окончания;
- голосовать может только участник, не за себя и один раз;
- MVP выбирается детерминированно при равенстве голосов;
- обработка и награды идемпотентны;
- UI различает Voting, Finished и Completed.

Production: migration и полный lifecycle regression test применены. Commit: `4c56097`. Статус: Готово.

### TASK-58 — удаление аккаунта

До изменения удалить аккаунт из приложения было нельзя.

Сделано:

- в Profile добавлено действие Delete Account с двумя подтверждениями, progress и безопасной ошибкой;
- клиент вызывает JWT-protected Edge Function методом DELETE и не отправляет user ID;
- функция берёт ID из проверенных claims, удаляет avatar, вызывает service-role-only `delete_user_data`, затем удаляет Auth user;
- профиль, memberships, votes, sport stats и reviews удаляются; у сохранённой общей истории матча `creator_id` становится `NULL`; агрегаты парков пересчитываются;
- локальная сессия очищается только после подтверждённого `deleted=true`.

Production: Edge Function `delete-account` v1 активна, `verify_jwt=true`. Одноразовый E2E подтвердил HTTP 200, невозможность повторного входа и отсутствие связанных строк. Commit: `ba5ba88`. Статус: Готово.

### TASK-16 — строка разрешения геолокации

До изменения `NSLocationWhenInUseUsageDescription` был пустым.

Добавлен английский purpose string для Debug/Release и `en.lproj/InfoPlist.strings`. Реальный system alert проверен после сброса разрешения на iPhone 17 Pro / iOS 26.5; Release warning отсутствует. Commits: `f779f8f`, `42f5b26`. Статус: Готово.

### TASK-21 — удаление неработающего Sign in with Apple

До изменения UI показывал полноценную, но всегда disabled Apple-кнопку.

Из release UI, ViewModel и Service удалены кнопка, разделитель, `AuthenticationServices` и мёртвый OAuth-путь. Версия 1.0 честно предлагает только email/password. Добавлен UI-тест отсутствия кнопки. Commit: `ea997a3`. Статус: Готово.

### TASK-59 — Privacy Policy и disclosures

До изменения не было политики, data map, App Store disclosure checklist и ссылки из приложения.

Сделано:

- добавлен экран `PrivacyPolicyView` и переход из Profile;
- созданы `docs/privacy-policy.md` и `docs/app-store-privacy.md`;
- описаны email, identifiers, avatar, gameplay/reviews, Supabase diagnostics и on-device location;
- подтверждено отсутствие advertising/analytics/tracking SDK;
- выбран support contact `gamespot.support@icloud.com`;
- Privacy Policy опубликована через изолированную ветку `gh-pages` по адресу <https://kotyarya.github.io/GameSpot/>; публикационный commit `5d673a6` не является частью текущей feature-ветки.
- из Release archive через Xcode Organizer сгенерирован и проверен `docs/GameSpot-PrivacyReport-2026-09-14.pdf`; отчёт пустой, а единственный manifest Swift Crypto не объявляет tracking, collected data или required-reason APIs.

Commits в рабочей ветке: `d452702`, `e7eb07d`, `ebaec28`, `dababa8`. Внесение готовых URL/contact/disclosures в App Store Connect и повтор отчёта из подписанного distribution archive выполняются в TASK-10 после Apple Developer membership. Статус: Готово.

### TASK-8 — детерминированные unit/UI tests

До изменения часть ViewModel tests ходила в production Supabase/Open-Meteo, Realtime channels делили состояние, а навигационный тест принимал экран Sign In за успешный main flow.

Сделано:

- введены небольшие service/realtime protocols и управляемые test doubles;
- unit tests `Games`, `GameInfo`, `Profile`, `CreateGame`, `Auth`, `SessionManager`, позднее Map/Park/ProfileSetup/AccountDeletion больше не требуют live backend;
- Realtime callbacks регистрируются до subscribe, channels уникальны и удаляются при cleanup;
- cancellation корректно снимает loader;
- добавлен реальный authenticated UI test: Sign In → tabs → Profile → Privacy Policy;
- тест устойчив к iOS 26 Save Password alert, неоднозначным accessibility labels и необходимости scroll;
- credentials берутся только из `GAMESPOT_UI_TEST_EMAIL`/`GAMESPOT_UI_TEST_PASSWORD`.

Проверка: 99/99 unit tests три последовательных раза, authenticated UI gate пройден, disposable account удалён, Release build успешен. Commits: `4edbbf7`, `3452ed0`. Статус: Готово.

### TASK-6 — конфигурация, Storage и общая безопасность

Сделано в iOS:

- Supabase URL и publishable key больше не зашиты в `SupabaseService.swift`; их читает `AppConfiguration` из Info.plist и валидирует при старте;
- service-role/private keys не добавлены;
- avatar encoder уменьшает изображение до 1024 px, перебирает JPEG quality и ограничивает результат 5 MiB;
- ошибки для пользователя не раскрывают backend details.

Сделано в Supabase:

- bucket `avatars`: public download URL, но metadata/list/write/delete только владельцу папки `{auth.uid()}`;
- допустимы JPEG/PNG до 5 MiB;
- фиксированный function `search_path`;
- закрыт hosted `rls_auto_enable()`;
- добавлены SQL security regressions.

Production: применено и проверено. Commits: `44847a3`, `91e38d5`. Статус: Готово.

### TASK-14 — Join/Leave UI

До изменения sheet держал устаревший snapshot, повторный tap был возможен, а ошибка могла остаться под sheet.

Сделано:

- локальное submitting state;
- блокировка Join/Leave/закрытия и повторного вызова во время запроса;
- после успеха `GameInfoViewModel` перечитывает details и sheet закрывается;
- ошибка остаётся внутри sheet;
- весь свободный slot стал tappable;
- добавлены DEBUG harness и 3 UI tests.

Commit: `c425c77`. Статус: Готово.

### TASK-15 — повторяемая работа с аватаром

До изменения фиксированный `avatar.jpg` загружался без upsert, а частичный сбой ломал retry и всё равно мог вызвать reload session.

Сделано:

- отдельный `AvatarStoring` service;
- путь `{userId}/avatar.jpg`, `upsert: true`, cache-busting URL;
- resize/compression до серверного лимита;
- Profile Setup пробрасывает ошибку и перечитывает session только после полного успеха;
- частичный сбой можно повторить;
- готовый Profile поддерживает add/replace/remove avatar;
- UI блокируется во время операции и не показывает ложный успех.

Production Storage rules применены через TASK-6. Commit: `792f6cc`. Статус: Готово.

### TASK-17 — детерминированная группировка игр по датам

До изменения тест сравнивал фиксированные даты мая с системным Today/Tomorrow и тестировал копию логики.

Сделано:

- production `GameSectionBuilder` используется и UI, и тестами;
- `Calendar`, `now`, `Locale` внедряются явно;
- проверены сортировка, часовые пояса Tokyo/Los Angeles и переход через полночь.

Commit: `9a9235f`. Статус: Готово.

### TASK-60 — email registration и password recovery

Сделано локально:

- sign-up учитывает реальный `AuthResponse`: session ведёт в приложение, отсутствие session — на Check your email/resend;
- добавлены Forgot password, нейтральный ответ, единая password policy и форма нового пароля;
- добавлен custom URL scheme `gamespot` и маршруты `gamespot://auth/confirmed`, `gamespot://auth/recovery`;
- `AuthLinkCoordinator` обменивает PKCE link на session, показывает expired/used error и не логирует URL/token/email/password;
- после смены пароля recovery session завершается и пользователь возвращается к Sign In;
- добавлены unit/UI tests.

Production email confirmation сейчас намеренно выключен (`mailer_autoconfirm=true`). Два redirect URL ещё не добавлены в hosted Auth allow-list: владелец был с телефона и dashboard login отложен. Поэтому реальный recovery email/deep-link E2E не завершён.

Commit: `44e09a0`. Статус: Тестирование.

### TASK-5 — устойчивые состояния контента

До изменения сетевые ошибки часто выглядели как корректные пустые списки или были видны только в log.

Сделано:

- единый `ContentStateView` с понятным текстом, action и accessibility ID;
- Map, Park, My Games, Game, Profile, Session restore и Profile Setup получили явные loading/error/empty/retry состояния;
- технические `localizedDescription` убраны из пользовательских сообщений;
- Weather failure не скрывает игру и не подставляет ложные нули;
- добавлены защиты от stale park/rating responses, double submit и partial profile load;
- DEBUG harness и UI tests проверяют error → Retry и slow loading → empty.

Проверка: 140/140 unit, 2/2 UI, Release build. Commit: `b3554c9`. Статус: Готово.

## Production Supabase: фактический результат

На дату снимка production `GameSpot` активен в `eu-north-1`, Postgres 17.6.1. В нём:

- 12 application tables в `public`;
- enum `teams`;
- 18 functions, из них 10 client-facing RPC, 4 lifecycle, 2 triggers/helpers, 1 delete RPC и hosted `rls_auto_enable`;
- 4 cron jobs с минутным расписанием;
- Realtime на `games`, `game_members`, `game_mvp_votes`, `profiles`, `sports`, `user_sport_stats`;
- public-download bucket `avatars`, 5 MiB, JPEG/PNG, owner-only metadata/write/delete;
- active Edge Function `delete-account`, JWT verification включена;
- 9 migration-history entries.

Security Advisor сейчас показывает шесть намеренных authenticated `SECURITY DEFINER` business RPC, `park_reviews` с RLS без прямых policies и выключенную leaked-password protection. Эти пункты описаны в [DATABASE.md](DATABASE.md) и [TODO.md](TODO.md); они не означают возврат прежнего публичного доступа `anon`.

## Git и публикации

- Рабочая ветка: `codex/gamespot-appstore`.
- `main` не изменялся и не сливался.
- Feature-ветка не была pushed в рамках этой работы.
- Единственный явно разрешённый внешний push — изолированная публикация privacy policy в `gh-pages`.
- TASK-55 добавит документацию отдельным commit после проверки.

## Источники

- Git history и diff `369ce9c..3452ed0`.
- Текущий Swift-код и SQL migrations в репозитории.
- Read-only catalog production Supabase от 12 сентября 2026 года.
- Задачи [TASK-56](https://app.notion.com/p/3bdb461e2b138108a5c7c2a943fc5b29), TASK-5, TASK-6, TASK-8, TASK-11–17, TASK-19, TASK-21, TASK-57–60 в Notion.
