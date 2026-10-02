# GameSpot Supabase Backend

This document describes the backend reproduced by the versioned migrations in the repository. Hosted project identifiers, operational metadata, credentials, and user data are intentionally excluded.

## Backend Components

GameSpot uses Supabase for:

- email/password authentication;
- PostgreSQL tables and server-side business rules;
- PostgREST reads and RPCs;
- Postgres Changes Realtime;
- avatar Storage;
- the account-deletion Edge Function;
- `pg_cron` match-lifecycle jobs.

The client connects with a publishable key. The key grants no privileged access by itself: table grants, RLS, and RPC grants define the actual boundary. The service role exists only inside the Supabase runtime and is never stored in the iOS app.

## Relationship Diagram

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

## Tables

### `profiles`

One application record per Auth user. The primary key matches `auth.users.id`, and a trigger creates the row after sign-up. Important fields include the unique `username`, `avatar_url`, `favorite_sport_id`, global ratings and counters, onboarding/profile-completion flags, and timestamps.

The client may update only `username`, `avatar_url`, `favorite_sport_id`, `is_onboarded`, and `is_profile_completed`, and only on its own row. Server functions own gameplay statistics.

### `user_sport_stats`

Per-sport `rating`, `games_played`, `mvp_count`, and `perf_points`. A profile trigger creates one row for each sport. Direct client writes are disabled.

### `user_reports`

Private user reports containing reporter, target, reason, optional details, moderation status, and a username/avatar snapshot. The unique `(reporter_id, reported_user_id, reason)` constraint makes duplicate submissions idempotent. Users can read only reports they submitted and cannot mutate rows directly.

### `user_blocks`

A private block list with primary key `(blocker_id, blocked_id)` and a username/avatar snapshot for management UI. Users read only their own blocks; mutations go through a validated RPC.

### Catalog and Venue Tables

- `sports` defines each sport, team size, duration, and minimum players for rewards.
- `parks` stores venue name, coordinates, address, activity status, and lighting.
- `parks_sports` is the many-to-many park/sport relationship.
- `parks_hour` stores weekly opening hours.
- `parks_images` stores catalog image URLs and the main-image flag.
- `parks_ratings` caches aggregate venue ratings.
- `park_reviews` stores one 1–5 review per user and park; writes go only through `rate_park`.

### `games`

A match references a park, creator, and sport and stores `starts_at`, duration, capacity, and lifecycle flags: `is_in_progress`, `is_finished`, `mvp_voting_open`, `participation_rewards_given`, and `is_processed`.

`creator_id` is nullable so shared match history can survive account deletion. Direct client writes are disabled.

### `game_members`

Stores membership and the `Team Alpha`/`Team Beta` enum, plus result snapshots: `rating_change`, `perf_points_earned`, and `was_mvp`. The production schema contains two equivalent unique constraints on `(game_id, user_id)`; this is harmless but remains technical debt.

### `game_mvp_votes`

Stores one vote per participant and game. Unique `(game_id, voter_id)` enforces one vote, while the RPC also validates membership and prevents self-voting.

## Functions and RPCs

### Authenticated Mutations

| Function | Behavior |
| --- | --- |
| `create_game(park,sport,starts_at)` | Validates identity, future time, available sport, and overlap; creates the game and creator membership |
| `join_game(game,team)` | Locks the game row and validates state, duplicate membership, and team capacity |
| `leave_game(game)` | Removes only the caller's membership before the match starts |
| `vote_mvp(game,user)` | Validates the voting window, membership, target, self-vote, and duplicate vote |
| `rate_park(user,park,...)` | Requires `auth.uid() = user`, validates 1–5 values, upserts the review, and rebuilds aggregates |
| `has_user_rated(user,park)` | Returns whether the user has already reviewed the venue |
| `submit_user_report(user,reason,details)` | Validates identity, target, and reason and safely ignores a duplicate |
| `set_user_block(user,is_blocked)` | Prevents self-blocking and idempotently creates or removes a private block |
| `is_username_available(username)` | Checks format, reserved/offensive rules, and uniqueness without exposing profiles |

These functions form a `SECURITY DEFINER` API surface. Only `authenticated` receives execute permission, and every mutation rechecks identity and state internally. Related Advisor warnings are therefore expected, but any body change requires another security review.

### Authenticated Reads

| Function | Result |
| --- | --- |
| `get_games_by_park(park)` | Venue games with sport and joined count |
| `get_user_games()` | Games for the current `auth.uid()` |
| `get_game_details(game)` | Game, venue, roster, flags, highlights, voting state, and MVP |
| `get_recent_matches()` | The caller's three latest completed matches |

These functions use `SECURITY INVOKER` and therefore follow the caller's grants and RLS. `get_game_by_id` exists but is not currently used by iOS.

### Internal Functions

| Function | Caller |
| --- | --- |
| `handle_new_user()` | Trigger after `auth.users INSERT` |
| `create_user_sport_stats()` | Trigger after `profiles INSERT` |
| `start_games()` | cron/service role |
| `finish_games()` | cron/service role |
| `open_mvp_voting()` | cron/service role |
| `process_finished_games()` | cron/service role |
| `delete_user_data(user)` | Service role from the Edge Function only |
| `rls_auto_enable()` | Hosted event-trigger helper; client execute revoked |

Application functions use a fixed `search_path = public, pg_temp`; the platform helper uses `pg_catalog`.

## Match Lifecycle

Four jobs run every minute:

| Job | Schedule | Command |
| --- | --- | --- |
| `start-games` | `* * * * *` | `select start_games();` |
| `finish-games` | `* * * * *` | `select finish_games();` |
| `open-mvp-voting` | `* * * * *` | `select open_mvp_voting();` |
| `process-finished-games` | `* * * * *` | `select process_finished_games();` |

1. Join and Leave are allowed before `starts_at`.
2. `start_games` marks the match in progress.
3. `finish_games` completes it after the configured duration.
4. `open_mvp_voting` checks the minimum-player threshold. Insufficient matches are processed without rewards; valid matches receive participation rewards once and open voting.
5. Participants vote during the three-minute post-match window.
6. `process_finished_games` chooses the winner, awards MVP rewards once, and marks the match processed.

Equal vote counts use the player UUID as a deterministic tie-breaker.

## Triggers

- `auth.users AFTER INSERT -> handle_new_user()`;
- `profiles AFTER INSERT -> create_user_sport_stats()`;
- hosted event trigger `ensure_rls` calls `rls_auto_enable()` for new tables and is unavailable to client roles.

## RLS and Grants

Every public application table has RLS enabled.

- `anon` can read only catalog tables: `parks`, `parks_hour`, `parks_images`, `parks_ratings`, `parks_sports`, and `sports`.
- `authenticated` can read the catalog plus the game/profile/stat data required by UI and Realtime.
- Direct client INSERT/UPDATE/DELETE rights on server-owned game, rating, and statistics tables are revoked.
- Profile updates are limited to the caller's row and safe columns.
- Blocked profiles are hidden from profile-backed social reads for the current user.
- `user_reports` and `user_blocks` expose only owner rows and no direct client mutations.
- `park_reviews` intentionally has RLS without a direct write policy because `rate_park` is the only write path.
- State mutations use validated RPCs.

Signed-in users can read the username, avatar, and game-visible statistics required by rosters and profiles. The Privacy Policy documents this visibility.

## Avatar Storage

- public bucket for URL-based downloads;
- object path `{lowercased-user-uuid}/avatar.jpg`;
- 5 MiB server limit;
- allowed MIME types: `image/jpeg`, `image/png`;
- metadata SELECT/INSERT/UPDATE/DELETE restricted to the authenticated owner folder;
- iOS uploads JPEG with `upsert: true` and cache-busting query parameters.

A public bucket means anyone who knows the exact URL can download an image, although listing and foreign writes remain blocked. Strict privacy would require a private bucket, signed URLs, and a client-model change.

## Account-Deletion Edge Function

`delete-account` accepts only DELETE and requires a valid JWT. Identity comes from JWT claims, never from the request body.

1. Remove `{userId}/avatar.jpg`.
2. Call service-role `delete_user_data(userId)`.
3. Delete the Auth user through the Admin API.
4. Return `{deleted:true}`.

Shared games remain with `creator_id = NULL`; profile-related rows are removed by cascades; venue aggregates are rebuilt after review deletion. The operation tolerates a missing avatar and partially completed prior cleanup.

## Realtime Publication

`supabase_realtime` includes `games`, `game_members`, `game_mvp_votes`, `profiles`, `sports`, and `user_sport_stats`. Client subscriptions are documented in [ARCHITECTURE.md](ARCHITECTURE.md). `sports` is published even though the current runtime does not subscribe to it directly.

## Migration History

1. `20260815151015_production_baseline.sql` — complete baseline schema.
2. `20260815152151_remove_debug_rpcs.sql` — removes debug RPCs.
3. `20260815152736_harden_rpc_privileges.sql` — RPC grants, invoker behavior, and search paths.
4. `20260815153230_harden_table_access.sql` — table grants, RLS, and column privileges.
5. `20260815153849_fix_game_lifecycle.sql` — lifecycle and MVP processing.
6. `20260815155612_add_account_deletion.sql` — service-only cleanup.
7. `20260815170136_harden_avatar_storage.sql` — bucket and policies.
8. `20260815191000_harden_function_search_paths.sql` — full search-path hardening.
9. `20260912084515_restrict_rls_auto_enable.sql` — hosted helper privileges.
10. `20260914145729_add_user_safety.sql` — reports, blocks, username policy, and profile visibility.
11. `20260916081437_task_20_optimize_advisors.sql` — indexes, canonical constraints, and policy cleanup.

New environments apply the complete migration set. Every schema change must add a migration; already applied files are never edited. Never run `db reset` against the hosted production project.

## Local Reproduction and Tests

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

The suite covers RPC privileges, RLS/table privileges, lifecycle processing, account deletion, avatar Storage, function security, and user safety. See [SETUP.md](SETUP.md) for installation details.

Authenticated `SECURITY DEFINER` functions are security-critical API endpoints: each has a fixed search path, explicit execute grants, and internal identity/invariant checks. Performance indexes are added from actual query plans rather than mechanically for every column.

Official references:

- [Supabase Database Linter](https://supabase.com/docs/guides/database/database-linter)
- [Storage access control](https://supabase.com/docs/guides/storage/security/access-control)
- [Password security](https://supabase.com/docs/guides/auth/password-security)
