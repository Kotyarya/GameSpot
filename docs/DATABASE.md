# Supabase backend GameSpot

Документ описывает backend, воспроизводимый из versioned migrations в репозитории. Hosted project identifiers, operational metadata, credentials и пользовательские данные намеренно не публикуются.

## Состав backend

Supabase используется для:

- email/password Auth;
- PostgreSQL tables и server-side business rules;
- PostgREST reads и RPC;
- Postgres Changes Realtime;
- Storage bucket аватаров;
- Edge Function удаления аккаунта;
- `pg_cron` для жизненного цикла матчей.

Клиент подключается publishable key. Такой ключ не даёт привилегий сам по себе: реальные границы задают table grants, RLS и RPC grants. Service role существует только внутри Supabase Edge Function/runtime и никогда не хранится в iOS.

## Схема связей

```mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : creates
    SPORTS ||--o{ PROFILES : favorite
    SPORTS ||--o{ USER_SPORT_STATS : measures
    PROFILES ||--o{ USER_SPORT_STATS : owns
    PARKS ||--o{ PARKS_SPORTS : offers
    SPORTS ||--o{ PARKS_SPORTS : available_at
    PARKS ||--o{ PARKS_HOUR : has
    PARKS ||--o{ PARKS_IMAGES : has
    PARKS ||--o| PARKS_RATINGS : aggregates
    PARKS ||--o{ PARK_REVIEWS : receives
    PROFILES ||--o{ PARK_REVIEWS : writes
    PARKS ||--o{ GAMES : hosts
    SPORTS ||--o{ GAMES : classifies
    PROFILES ||--o{ GAMES : creates
    GAMES ||--o{ GAME_MEMBERS : contains
    PROFILES ||--o{ GAME_MEMBERS : joins
    GAMES ||--o{ GAME_MVP_VOTES : receives
    PROFILES ||--o{ GAME_MVP_VOTES : voter
    PROFILES ||--o{ GAME_MVP_VOTES : voted_player
    PROFILES ||--o{ USER_REPORTS : reporter
    PROFILES ||--o{ USER_REPORTS : reported_user
    PROFILES ||--o{ USER_BLOCKS : blocker
    PROFILES ||--o{ USER_BLOCKS : blocked_user
```

## Таблицы

### `profiles`

Одна прикладная запись на Auth user. PK `id` совпадает с `auth.users.id` и создаётся trigger после signup.

Важные поля: `username` unique, `avatar_url`, `favorite_sport_id`, global `rating`, `games_played`, `mvp_count`, `perf_points`, `is_onboarded`, `is_profile_completed`, timestamps. FK: `favorite_sport_id -> sports.id`.

Клиент может UPDATE только пять колонок: `username`, `avatar_url`, `favorite_sport_id`, `is_onboarded`, `is_profile_completed`, и только своей строки. Игровую статистику меняют server functions.

### `user_sport_stats`

Per-sport статистика пользователя: `rating`, `games_played`, `mvp_count`, `perf_points`. PK `id`; FK `user_id -> profiles.id`, `sport_id -> sports.id`. Записи для всех sports создаются trigger при создании profile. Прямых client writes нет.

### `user_reports`

Приватные жалобы пользователей. Хранит reporter/target, reason, optional details,
status и snapshot username/avatar на момент жалобы. Unique
`(reporter_id, reported_user_id, reason)` делает повторную отправку одного типа
идемпотентной. Клиент читает только собственные отправленные жалобы и не может
напрямую создавать, изменять или удалять строки.

### `user_blocks`

Приватный список блокировок с PK `(blocker_id, blocked_id)` и snapshot
username/avatar для экрана управления. Клиент читает только свои блокировки;
изменения выполняются через проверенный RPC.

### `sports`

Справочник видов спорта. Поля: unique `name`, `players_per_team`, `duration_minutes`, `minimum_players_for_rewards`. Текущий client распознаёт football, basketball, volleyball. Читается публично; изменяется только административно.

### `parks`

Справочник площадок: unique `name`, latitude/longitude, address, `is_active`, `has_lighting`. Карта выбирает только active rows. Читается публично.

### `parks_sports`

Связь many-to-many park ↔ sport. PK bigint `id`; FK `park_id`, `sport_id`. Определяет допустимые sports для создания игры на площадке.

### `parks_hour`

Недельное расписание: `day_of_week`, `open_hour`, `close_time`, `is_closed`, FK `park_id`. Интерпретация open/closed выполняется в iOS presentation logic.

### `parks_images`

URL изображений площадки и `is_main`, FK `park_id`. Это не avatar Storage; здесь хранятся только ссылки каталога.

### `parks_ratings`

Кэш агрегатов по площадке: average/count для quality, facilities, activity, `overall_avg`, `updated_at`, FK `park_id`. Клиент не пишет таблицу напрямую; `rate_park` пересчитывает агрегат из reviews.

### `park_reviews`

Индивидуальная оценка пользователя 1–5 по трём категориям. PK UUID; FK `user_id -> profiles`, `park_id -> parks`; unique `(user_id, park_id)`. Прямых client privileges/policies на запись нет: доступ идёт через `rate_park`.

### `games`

Матч: park, creator, sport, `starts_at`, duration, capacity и state flags:

- `is_in_progress`;
- `is_finished`;
- `mvp_voting_open`;
- `participation_rewards_given`;
- `is_processed`.

PK UUID; FK park/sport и nullable `creator_id -> profiles`. Nullable creator позволяет сохранить shared match history после удаления аккаунта. Direct client writes запрещены.

### `game_members`

Участник матча и команда enum `Team Alpha`/`Team Beta`. Также хранит snapshot результата: `rating_change`, `perf_points_earned`, `was_mvp`. PK UUID; FK user/game. В production существуют два одинаковых unique constraints на `(game_id,user_id)` — функционально безопасно, но это technical debt.

### `game_mvp_votes`

Один голос участника за другого участника: `voter_id`, `voted_id`, `game_id`, timestamp. Unique `(game_id,voter_id)` обеспечивает один голос. Self-vote и membership дополнительно проверяет RPC.

## Functions и RPC

### Client-facing authenticated mutations

| Function | Поведение |
| --- | --- |
| `create_game(park,sport,starts_at)` | проверяет auth, будущее время, доступность sport, overlap; создаёт game и creator membership |
| `join_game(game,team)` | блокирует game row, проверяет pre-start state, duplicate и team capacity |
| `leave_game(game)` | разрешает удалить только собственное membership до старта |
| `vote_mvp(game,user)` | проверяет voting window, membership, target, self-vote и duplicate |
| `rate_park(user,park,...)` | требует `auth.uid() = user`, валидирует 1–5, upsert review и пересчитывает aggregate |
| `has_user_rated(user,park)` | возвращает наличие review; используется для формы rating |
| `submit_user_report(user,reason,details)` | проверяет auth/target/reason, безопасно игнорирует duplicate и создаёт pending report |
| `set_user_block(user,is_blocked)` | проверяет auth/self-block и идемпотентно создаёт или удаляет private block |
| `is_username_available(username)` | проверяет format/reserved/offensive policy и unique username без раскрытия `profiles` |

Это `SECURITY DEFINER` API-поверхность. Execute есть у `authenticated`, а внутри mutating functions проверяется identity/state. Поэтому соответствующие Advisor WARN являются ожидаемыми, но каждое изменение function body требует повторного security review.

### Authenticated reads

| Function | Результат |
| --- | --- |
| `get_games_by_park(park)` | список игр площадки с sport и joined count |
| `get_user_games()` | игры текущего `auth.uid()` |
| `get_game_details(game)` | game, park, roster, flags, highlights, vote state и MVP |
| `get_recent_matches()` | последние три завершённых матча текущего пользователя |

Эти функции работают как `SECURITY INVOKER`, поэтому подчиняются grants/RLS вызывающего пользователя. `get_game_by_id` существует, но iOS его сейчас не вызывает.

### Internal functions

| Function | Кто вызывает |
| --- | --- |
| `handle_new_user()` | trigger после `auth.users INSERT`; создаёт profile |
| `create_user_sport_stats()` | trigger после `profiles INSERT`; создаёт sport stats |
| `start_games()` | cron/service role |
| `finish_games()` | cron/service role |
| `open_mvp_voting()` | cron/service role |
| `process_finished_games()` | cron/service role |
| `delete_user_data(user)` | только service role из Edge Function |
| `rls_auto_enable()` | hosted event trigger helper; client execute отозван |

У всех application functions фиксированный `search_path = public, pg_temp`; у platform helper — `pg_catalog`.

## Жизненный цикл матча

Каждую минуту работают четыре jobs:

| Job | Schedule | Команда |
| --- | --- | --- |
| `start-games` | `* * * * *` | `select start_games();` |
| `finish-games` | `* * * * *` | `select finish_games();` |
| `open-mvp-voting` | `* * * * *` | `select open_mvp_voting();` |
| `process-finished-games` | `* * * * *` | `select process_finished_games();` |

Последовательность:

1. До `starts_at` разрешены Join/Leave.
2. `start_games` ставит `is_in_progress`.
3. После полной duration `finish_games` завершает игру.
4. `open_mvp_voting` проверяет minimum players. При нехватке игра сразу processed без rewards. Иначе participation rewards начисляются один раз и открывается voting.
5. Участники голосуют в течение 3 минут после окончания.
6. `process_finished_games` выбирает лидера, начисляет MVP rewards один раз и ставит processed.

Tie-break при равных голосах — UUID игрока, а не random, поэтому повторяемость сохранена.

## Triggers

- `auth.users AFTER INSERT -> handle_new_user()`;
- `profiles AFTER INSERT -> create_user_sport_stats()`;
- hosted event trigger `ensure_rls` вызывает `rls_auto_enable()` для новых таблиц и не доступен клиентским ролям.

## RLS и grants

Все public application tables имеют RLS.

- `anon`: SELECT только catalog tables `parks`, `parks_hour`, `parks_images`, `parks_ratings`, `parks_sports`, `sports`.
- `authenticated`: catalog + game/profile/stat reads, необходимые UI и Realtime.
- прямой INSERT/UPDATE/DELETE server-owned game/rating/stat tables у client roles отозван;
- `profiles` UPDATE ограничен own row и безопасными columns;
- blocked profiles скрываются из profile-backed social reads текущего пользователя;
- `user_reports` и `user_blocks` доступны только owner rows; direct client mutations отозваны;
- `park_reviews` намеренно имеет RLS без direct policy, потому что запись только через `rate_park`;
- client-facing state mutations выполняются через проверенные RPC.

Публичное чтение profiles/stats для signed-in пользователей необходимо roster/profile Realtime. Это означает, что username/avatar/game-visible stats не являются приватными внутри приложения; это отражено в Privacy Policy.

## Storage `avatars`

- bucket public для download по URL;
- object path: `{lowercased-user-uuid}/avatar.jpg`;
- server limit: 5 MiB;
- MIME allow-list: `image/jpeg`, `image/png`;
- metadata SELECT, INSERT, UPDATE, DELETE доступны только `authenticated` owner собственной папки;
- iOS всегда загружает JPEG с `upsert: true` и добавляет query parameter для cache busting.

Public bucket означает: знающий URL может загрузить изображение без auth. Bucket listing и чужие writes при этом закрыты. Если avatars должны стать строго приватными, потребуется private bucket + signed URLs и изменение client model.

## Edge Function `delete-account`

Edge Function `delete-account` требует валидный JWT и не принимает identity из request body.

Принимается только DELETE. Gateway проверяет JWT; handler берёт user ID из claims, а не request body. Порядок:

1. удалить `{userId}/avatar.jpg`;
2. вызвать service-role `delete_user_data(userId)`;
3. удалить Auth user через Admin API;
4. вернуть `{deleted:true}`.

Shared games сохраняются с `creator_id = NULL`; связанные rows удаляются через profile/FK cascades; park aggregates после удаления reviews пересчитываются. Операция retry-safe для уже удалённого avatar/partial data cleanup насколько допускают Supabase APIs.

## Realtime publication

В `supabase_realtime` включены:

- `games`;
- `game_members`;
- `game_mvp_votes`;
- `profiles`;
- `sports`;
- `user_sport_stats`.

Клиентские подписки описаны в [ARCHITECTURE.md](ARCHITECTURE.md). `sports` опубликована, хотя отдельной runtime subscription на неё сейчас нет.

## Migrations

Локальный порядок:

1. `20260815151015_production_baseline.sql` — полная исходная схема.
2. `20260815152151_remove_debug_rpcs.sql` — удаление debug RPC.
3. `20260815152736_harden_rpc_privileges.sql` — RPC grants/invoker/search path.
4. `20260815153230_harden_table_access.sql` — table grants/RLS/column privileges.
5. `20260815153849_fix_game_lifecycle.sql` — lifecycle и MVP.
6. `20260815155612_add_account_deletion.sql` — service-only cleanup.
7. `20260815170136_harden_avatar_storage.sql` — bucket и policies.
8. `20260815191000_harden_function_search_paths.sql` — полный search-path pass.
9. `20260912084515_restrict_rls_auto_enable.sql` — hosted helper privileges.
10. `20260914145729_add_user_safety.sql` — reports, blocks, username policy и profile visibility.
11. `20260916081437_task_20_optimize_advisors.sql` — indexes, canonical constraints и policy cleanup.

Новый environment создаётся полным локальным набором migrations. Новые изменения всегда добавляются новой migration; уже применённые файлы не редактируются. Hosted database нельзя сбрасывать командой `db reset`.

## Локальное воспроизведение и тесты

```bash
supabase start
supabase db reset --local --no-seed

DATABASE_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
for test_file in supabase/tests/database/*.sql; do
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$test_file"
done

supabase db diff --local --schema public,storage
supabase stop
```

Набор tests: RPC privileges, table/RLS privileges, lifecycle, account deletion, avatar Storage, function security и user safety. Подробная установка — [SETUP.md](SETUP.md).

## Security validation

Локальная проверка включает database lint, regression scripts для grants/RLS/RPC,
полный lifecycle игры, удаление аккаунта, Storage policies и user safety.
Authenticated `SECURITY DEFINER` functions считаются частью security-critical API:
для них фиксируется `search_path`, явно назначается `EXECUTE`, а identity и
инварианты повторно проверяются внутри функции. Performance-индексы добавляются
по реальным query plans, а не механически для каждой колонки.

Официальные remediation pages:

- [Supabase Database Linter](https://supabase.com/docs/guides/database/database-linter)
- [Storage access control](https://supabase.com/docs/guides/storage/security/access-control)
- [Password security](https://supabase.com/docs/guides/auth/password-security)
