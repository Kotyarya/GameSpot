# Key Technical Decisions

This is a compact Architecture Decision Record. Where the original motivation was not recorded, the document says so instead of presenting an observed benefit as historical fact.

## ADR-001 — Native SwiftUI Client

**Context.** GameSpot is an iOS diploma and portfolio application; no original UIKit/Flutter comparison survives.

**Decision.** Use Swift, SwiftUI, MapKit, Core Location, and Swift Concurrency. The minimum target is iOS 26.0 and the UI uses iOS 26 Liquid Glass APIs.

**Consequences.** Strong Apple-framework integration and simple system permissions, but an Apple-only product with a high deployment target and recent Xcode requirement.

## ADR-002 — Supabase as the Complete Backend

**Context.** The app needs authentication, relational data, server functions, files, and live updates.

**Decision.** Use hosted Supabase Auth, Postgres, PostgREST/RPC, Realtime, Storage, and Edge Functions.

**Consequences.** Less infrastructure and no separate server repository, with a strong dependency on Supabase APIs, correct RLS/grants, versioned migrations, and internet access.

## ADR-003 — Feature-Oriented MVVM Without a Separate Domain Layer

**Decision.** Use Views, `@MainActor ObservableObject` ViewModels, and domain services. Group feature code by screen area and shared models/services under Core.

**Consequences.** Data flow is readable and protocol-testable, but ViewModels sometimes coordinate infrastructure operations and large Views still contain presentation logic.

## ADR-004 — Shared Production Services with Protocol Testing Seams

**Context.** Early ViewModel tests contacted live Supabase/Open-Meteo and depended on order and Realtime state.

**Decision.** Keep shared production defaults but accept narrow service protocols through initializers.

**Consequences.** Deterministic unit tests with simple runtime wiring; environment replacement is harder than with a complete composition root.

## ADR-005 — PostgreSQL Owns Gameplay Rules

**Decision.** Perform game-state mutations through `SECURITY DEFINER` RPCs using `auth.uid()`, row locks, and server time. Revoke direct client writes to server-owned tables.

**Consequences.** Capacity, ownership, time, votes, and rewards are consistent across clients. Function bodies, grants, and search paths become security-critical and require review.

## ADR-006 — Read-Mostly Data API and Explicit Grants

**Decision.** Let `anon` read only the static catalog and `authenticated` read the game/profile data required by the UI. Allow writes through RPCs except for five safe profile columns.

**Consequences.** Smaller attack surface and protected calculated statistics; each new mutation requires a migration/RPC rather than only a Swift call.

## ADR-007 — Versioned Baseline and Forward-Only Migrations

**Context.** The backend originally existed only in production without migration history.

**Decision.** Record an exact baseline in Git, register it against the existing hosted project without rerunning CREATE statements, and add fixes as new migrations.

**Consequences.** New environments are reproducible. Existing production requires a strict distinction between registering and executing the baseline. Applied migrations are never edited.

## ADR-008 — Cron-Driven Match Lifecycle

**Decision.** Run four idempotent lifecycle functions every minute: start, finish, open voting/award participation, and process MVP.

**Consequences.** State changes do not depend on an open iPhone, although UI transitions can lag by up to one minute. Cron and service-role access must remain unavailable to clients.

## ADR-009 — Three-Minute MVP Window and Deterministic Tie-Break

**Decision.** Award participation once after a valid match finishes, keep MVP voting open until three minutes after the end, and break equal vote counts by player UUID.

**Consequences.** Processing is repeatable and tests are deterministic. The short window suits a demo but may need revision for a real user base.

## ADR-010 — Realtime as Invalidation

**Decision.** Treat each Realtime event as a signal to rerun the authoritative query or RPC rather than locally applying a partial row payload.

**Consequences.** Correct composite snapshots at the cost of more requests. Higher traffic would require debounce, coalescing, or more targeted updates.

## ADR-011 — Unique Realtime Channel per Instance

**Decision.** Give every Realtime service a unique channel, register handlers before subscribing, and remove the channel during cleanup.

**Consequences.** Screen and test lifecycles do not conflict, provided ViewModels unsubscribe and do not remain alive unnecessarily.

## ADR-012 — Fixed Avatar Path with Upsert

**Decision.** Store one `{userId}/avatar.jpg`, resize the client image to at most 1024 px and 5 MiB JPEG, upload with `upsert:true`, and use a cache-busting URL.

**Consequences.** Safe retries, simple deletion, and no orphaned versions; no avatar history is retained.

## ADR-013 — Public-Download Avatar Bucket

**Decision.** Keep downloads public for the existing `avatar_url` model while restricting listing, metadata, writes, and deletion to the owner folder.

**Consequences.** Anyone with the exact object URL can download it. Strict privacy would require a private bucket, signed URLs, and a different client model.

## ADR-014 — Account Deletion Through an Edge Function

**Decision.** A JWT-protected DELETE Edge Function reads identity only from verified claims, runs service-only SQL cleanup, and uses Auth Admin to delete the user.

**Consequences.** The iOS app never contains a service key. The deployable function and its multi-step external work must remain retry-safe.

## ADR-015 — Preserve Shared Match History After Account Deletion

**Decision.** Set `games.creator_id` to NULL while deleting personal memberships, votes, statistics, reviews, and profile data and rebuilding park aggregates.

**Consequences.** Other participants retain their match history. List RPCs and Swift models must accept a missing creator.

## ADR-016 — Email and Password Only for Version 1.0

**Context.** A disabled Sign in with Apple control was visible, but OAuth was not implemented.

**Decision.** Remove Apple sign-in and keep working email/password authentication and recovery.

**Consequences.** A smaller, truthful authentication surface. Apple sign-in can return only as a complete separate feature.

## ADR-017 — Custom URL Scheme for Auth Callbacks

**Decision.** Use `gamespot://auth/confirmed` and `gamespot://auth/recovery`, route by scheme/host/path, and exchange PKCE sessions through the Supabase SDK.

**Consequences.** Hosted Supabase must allow-list both URLs. Another app can claim a custom scheme, so PKCE/token verification remains mandatory; Universal Links would be stronger for a larger product.

## ADR-018 — Shared User-Safe Content State

**Decision.** Use `ContentStateView`, explicit loading/error/empty values, and Retry actions rather than raw `localizedDescription` or ambiguous empty content.

**Consequences.** Predictable UI and stable test identifiers, with ViewModels responsible for explicit state and cancellation paths.

## ADR-019 — On-Device Location and Keyless Weather Provider

**Decision.** Keep foreground Core Location data on the device and send only the selected park coordinates/time to Open-Meteo.

**Consequences.** No background tracking or backend location rows, but the forecast requires internet and depends on an external provider.

## ADR-020 — Portfolio Scope Before Scale

**Decision.** Do not add monetization, analytics, speculative infrastructure, broad refactors, or high-load optimization without a concrete release blocker.

**Consequences.** The project stays understandable and verifiable. Any startup expansion should begin with a new requirements and load audit rather than assuming the portfolio architecture is already production-scale.
