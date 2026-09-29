# GameSpot working agreement

## Objective and source of truth

- The current objective is to make GameSpot ready for App Store submission as a portfolio application.
- Notion epic TASK-56 and its related GameSpot tasks are the source of truth for scope and progress.
- Work on one task at a time. Prefer the highest-priority unblocked task whose dependencies are satisfied.
- Keep the portfolio scope small: do not add monetization, growth systems, broad refactors, or speculative infrastructure.

## Task workflow

1. Read the selected Notion task and inspect the current repository/backend state.
2. Move the task to `В работе` and record a concise implementation approach.
3. Implement the smallest complete solution that satisfies every acceptance criterion.
4. Run proportionate builds, tests, security checks, and review.
5. Fix issues found by verification before considering the task complete.
6. Commit one logical task at a time with the Notion task ID in the commit subject.
7. Update Notion with the result, verification evidence, and commit hash.
8. Set `Definition of Done` and move to `Готово` only when authoritative evidence proves completion.
9. If genuinely blocked, record the exact blocker in Notion and select the next safe unblocked task.

## Git rules

- Use branch `codex/gamespot-appstore`; never commit directly to `main`.
- Preserve user changes and unrelated work.
- Do not push, merge, open a pull request, rewrite history, or delete branches without explicit user approval.
- Do not use destructive Git commands.
- Use concise commit subjects such as `chore(TASK-19): version Supabase schema`.

## iOS verification

- Keep the app compatible with its configured Swift, Xcode, and iOS deployment targets unless a task explicitly changes them.
- For Swift changes, build the Release configuration and run the relevant unit/UI tests.
- Treat warnings that affect privacy, permissions, App Review, or runtime correctness as release blockers.
- Do not claim a user flow works solely from compilation; verify behavior or add focused tests where practical.

## Supabase rules

- Treat the connected GameSpot project as production data.
- Store every schema, RLS, grant, function, trigger, index, Storage policy, and cron change in versioned migrations.
- Never include service-role keys, database passwords, access tokens, user data, or other secrets in Git.
- Never run remote reset, destructive SQL, delete data, deploy an irreversible migration, or create paid resources without explicit user approval.
- Read-only inspection is allowed. Before any non-destructive production schema mutation, present the migration and verification plan and obtain approval when the change can affect live behavior.
- Prefer explicit grants, least privilege, stable `search_path`, ownership checks, and server-side enforcement of game invariants.

## App Store boundaries

- Do not spend money, enroll in paid services, publish the app, submit to App Review, or change the agreed product scope without explicit user approval.
- Privacy Policy, account deletion, truthful permission prompts, stable authentication, basic user reporting/blocking, and the reviewer journey are mandatory for version 1.0.
