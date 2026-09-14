# Состояние GameSpot и точка возврата

Снимок: 14 сентября 2026 года, ветка `codex/gamespot-appstore`. Notion epic: [TASK-56](https://app.notion.com/p/3bdb461e2b138108a5c7c2a943fc5b29).

Цель текущего этапа — App Store portfolio release, не развитие стартапа.

## Working

Подтверждено кодом и автоматизированной проверкой:

- email/password sign in/sign up и session state;
- onboarding, foreground location permission и Profile Setup;
- карта active parks, park details, hours/images/sports/rating;
- Create Game через server RPC;
- My Games и park games;
- Join/Leave с single-flight UI и server-state checks;
- server lifecycle scheduled → live → finished/voting → processed;
- participation/MVP rewards и защита статистики от client writes;
- Profile, global/per-sport stats, ranks, recent matches;
- avatar add/replace/remove с retry-safe Storage;
- Realtime reload для games, details и profile;
- optional weather через Open-Meteo;
- in-app Privacy Policy и публичная HTTPS policy;
- in-app account deletion через JWT Edge Function;
- local user reporting/blocking flow, username moderation и owner runbook;
- loading/error/empty/retry states на основном reviewer journey;
- versioned Supabase schema и семь SQL regression suites.

Последние сохранённые evidence: 147/147 unit tests, authenticated Privacy UI path PASS, Release Simulator build PASS, TASK-78 local SQL regression PASS, local Security Advisor без замечаний, production SQL regressions 6/6, account deletion production E2E PASS.

## Current release gates

### TASK-60 — production password recovery

Статус: Тестирование.

Нужно на компьютере войти в Supabase Dashboard и добавить exact Redirect URLs:

- `gamespot://auth/confirmed`;
- `gamespot://auth/recovery`.

После этого проверить request → email → deep link → new password → sign in. Не менять Site URL/SMTP/templates одновременно без отдельного решения.

### TASK-59 — App Store privacy metadata

Статус: Готово.

Подготовлено и проверено:

- Privacy Policy: <https://kotyarya.github.io/GameSpot/>;
- support: `gamespot.support@icloud.com`;
- категории из [app-store-privacy.md](app-store-privacy.md);
- Privacy Report из Release archive: [GameSpot-PrivacyReport-2026-09-14.pdf](GameSpot-PrivacyReport-2026-09-14.pdf).

Внесение URL/contact/disclosures в App Store Connect и повторная проверка уже
подписанного distribution archive перенесены в TASK-10, потому что требуют Apple
Developer membership и App Store Connect app record.

### TASK-78 — reporting и blocking

Статус: локальная реализация и автоматизированная проверка завершены. Добавлены
report/block RPC, RLS, username policy, публичный профиль, скрытие заблокированных
игроков, Unblock и manual moderation runbook. До статуса «Готово» нужны отдельное
разрешение на применение migration к production Supabase и ручной E2E с двумя
production test accounts.

### TASK-9 — portfolio/App Store материалы

README и техническая документация обновлены TASK-55, но screenshots и demo video не подготовлены. Нужны финальные screenshots без тестовых/персональных данных и короткая reviewer/demo последовательность.

### TASK-10 — TestFlight

Заблокировано Apple Developer membership и оставшимися critical gates. Требует signing, archive, upload, TestFlight install и ручной device run. Не выполнять платные действия без решения владельца.

## Known bugs / correctness risks

### Deleted creator может сломать декодирование списка игр

Backend account deletion сохраняет shared game и устанавливает `games.creator_id = NULL`, но Swift `Game.creatorId` объявлен non-optional `UUID`. List RPC возвращает `creator_id` как есть. Если удаляемый пользователь создал game с другими участниками, последующая загрузка списка может получить `null` и упасть на decoding всего ответа.

Это подтверждённая несовместимость schema/model, но production E2E её не покрывал, потому что disposable account не создавал shared game. Нужно создать отдельную Notion-задачу: сделать `creatorId` optional или гарантировать non-null anonymous owner, добавить SQL+iOS regression и проверить UI.

### Recovery end-to-end не проверен

Код и unit/UI states готовы, но hosted allow-list отсутствует. Это release gate TASK-60, а не доказанный defect implementation.

### Notion parent statuses частично устарели

TASK-3 всё ещё заблокирована старой причиной про authenticated account, хотя TASK-8 уже прошла реальный authenticated flow. TASK-4 всё ещё пишет, что TASK-13 ждёт production verification, хотя TASK-13 готова. Перед финальным release board следует актуализировать parent tasks, не меняя историю child tasks.

## Technical debt

### Backend

- duplicate unique constraints/indexes `unique_game_member` и `unique_member_per_game`;
- 15 FK без covering indexes; оптимизировать только после реальных query plans/роста data;
- две overlapping permissive SELECT policies на `profiles` и `user_sport_stats`;
- `has_user_rated` принимает `p_user_id`; безопаснее выводить user из `auth.uid()`;
- leaked-password protection Supabase выключена;
- public avatar URLs доступны знающему URL;
- `sports` включена в Realtime publication, хотя client не подписывается;
- baseline содержит историческую структуру и не должен переписываться.

### iOS

- крупные `ParkInfoView`, `GameInfoView`, `ProfileView` затрудняют review;
- production dependencies используют singleton defaults, нет environment container;
- Supabase configuration хранится в Info.plist, а не `.xcconfig` per environment;
- Realtime invalidation делает полный reload без debounce;
- Profile Setup координирует Storage и profile update без общей транзакции;
- network/RPC DTO задаются вручную строками;
- нет offline cache;
- minimum iOS 26 резко ограничивает аудиторию;
- app ориентирован на английский; полной локализации нет.

Для portfolio 1.0 эти пункты не требуют broad refactor, кроме creator-null correctness bug.

## Not implemented

- Sign in with Apple;
- push notifications;
- offline mode;
- app-owned analytics/crash reporting;
- payments/ads/monetization;
- background location;
- полноценный park text search/filter;
- admin/moderation panel;
- CI/CD;
- universal links для Auth;
- screenshots/demo video;
- App Store Connect record, TestFlight и submission.

## Backlog tasks: оценка актуальности

- TASK-7 code cleanup: не брать до release blocker; broad refactor противоречит scope.
- TASK-18 authenticated navigation: основная цель уже фактически покрыта TASK-8; проверить критерии и закрыть/отменить как duplicate, если дополнительного flow нет.
- TASK-20 Advisor/Auth: часть security исправлена; оставшиеся notices перечислены выше. Разделить на leaked-password setting и необязательную performance cleanup, если задача будет выполняться.
- TASK-76 отменена как duplicate TASK-60 — оставить отменённой.

## If development resumes

Приоритетный порядок:

1. Исправить nullable creator mismatch и добавить regression.
2. Завершить TASK-60 через hosted Redirect URLs и recovery E2E.
3. Реализовать минимальный TASK-61 report/block flow.
4. После Apple Developer membership внести готовые privacy/support данные в App Store Connect и повторно проверить signed archive (TASK-10).
5. Подготовить screenshots/reviewer instructions (TASK-9).
6. Купить/активировать Apple Developer membership только когда всё выше готово.
7. Выполнить device Release + TestFlight (TASK-10).
8. Только после успешной публикации рассматривать performance debt и refactor.

Перед каждым шагом читать конкретную Notion task, [ARCHITECTURE.md](ARCHITECTURE.md), [DATABASE.md](DATABASE.md) и [SETUP.md](SETUP.md).
