# Ключевые технические решения

Это упрощённый журнал ADR. Где первоначальная причина выбора не зафиксирована, она явно помечена как неизвестная; наблюдаемая польза не выдаётся за историческую мотивацию.

## ADR-001 — нативный SwiftUI client

**Context.** GameSpot создан как iOS/diploma/portfolio приложение. Точная запись первоначального сравнения UIKit, Flutter и других вариантов не найдена.

**Decision.** Использовать Swift/SwiftUI, MapKit, Core Location и Swift Concurrency. Minimum target — iOS 26.0; интерфейс использует iOS 26 Liquid Glass APIs.

**Reason.** Историческая причина выбора неизвестна. Фактически стек демонстрирует современную нативную iOS-разработку и тесную интеграцию с Apple frameworks.

**Consequences.** Простой доступ к MapKit и системным permissions; только Apple platform; высокий deployment target резко ограничивает совместимые устройства и требует нового Xcode.

## ADR-002 — Supabase как единый backend

**Context.** Нужны Auth, relational data, server functions, files и live updates. Документированного исходного vendor comparison нет.

**Decision.** Использовать hosted Supabase: Auth + Postgres + PostgREST/RPC + Realtime + Storage + Edge Functions.

**Reason.** Историческая причина неизвестна. Наблюдаемый результат — один backend покрывает все требования небольшого портфолио-приложения без отдельного server repository.

**Consequences.** Меньше инфраструктуры; сильная связь с Supabase APIs и policies; критично правильно настроить RLS/grants и version migrations; app требует internet.

## ADR-003 — feature-oriented MVVM без отдельного domain/repository слоя

**Context.** UI должен отделять async state от сетевых вызовов, но проект остаётся небольшим.

**Decision.** Views + `@MainActor ObservableObject` ViewModels + domain services. Files группируются по Features, общие Models/Services — в Core.

**Reason.** Это соответствует текущему коду и удерживает portfolio scope. Отдельный repository/use-case слой не добавлялся без необходимости.

**Consequences.** Поток данных читаем и тестируем через protocols; ViewModels местами координируют несколько инфраструктурных операций; некоторые большие Views всё ещё содержат presentation logic.

## ADR-004 — singleton production services + protocol seams для tests

**Context.** Первоначальные ViewModel tests вызывали live Supabase/Open-Meteo и зависели от порядка/Reatime state.

**Decision.** Оставить `shared` service defaults в production, но принимать узкие protocols через initializer.

**Reason.** Минимальное изменение устраняет внешние зависимости unit tests без внедрения DI framework.

**Consequences.** Tests детерминированы; production wiring остаётся простым. Полноценная смена environment или deep dependency graph будет сложнее, чем с composition root.

## ADR-005 — PostgreSQL является источником истины для игровых правил

**Context.** Client можно модифицировать; прямые table writes и UI-only checks не защищают capacity, ownership, time и rewards.

**Decision.** Все state mutations игры выполняются через `SECURITY DEFINER` RPC с `auth.uid()`, row locks и server time. Direct client writes server-owned tables отозваны.

**Reason.** Нельзя позволять клиенту подменять creator, membership, votes или statistics.

**Consequences.** Правила едины для всех clients и проверяемы SQL tests. Functions становятся security-critical API; каждый body/grant/search_path требует review.

## ADR-006 — read-mostly Data API и явные grants

**Context.** RLS с broad `USING/WITH CHECK true` позволял обходить RPC.

**Decision.** `anon` читает только статический каталог; `authenticated` читает нужные game/profile data; writes разрешены через RPC, кроме пяти safe profile columns.

**Reason.** Least privilege и защита вычисляемой статистики.

**Consequences.** Меньше attack surface. Добавление новой client mutation требует migration/RPC, а не только Swift call.

## ADR-007 — версионируемый baseline и миграции только вперёд

**Context.** Backend был создан вручную в production, migration history отсутствовала.

**Decision.** Зафиксировать точный baseline в Git, зарегистрировать его в existing production без повторного CREATE и оформлять исправления отдельными migrations.

**Reason.** Воспроизводимость, code review и возможность восстановить новый environment.

**Consequences.** Новый environment поднимается clean reset. Existing production требует осторожного distinction между «register baseline» и «execute baseline». Applied migrations не редактируются.

## ADR-008 — server-driven match lifecycle через cron

**Context.** Статус должен меняться даже когда ни один iPhone не открыт. Исходный 20-second voting threshold конфликтовал с duration.

**Decision.** Четыре idempotent lifecycle functions запускаются `pg_cron` каждую минуту: start, finish, open voting/rewards, process MVP.

**Reason.** Server time и независимость от client lifecycle.

**Consequences.** Переходы могут визуально запаздывать до минуты; rules централизованы; cron/service role должны быть закрыты от clients.

## ADR-009 — трёхминутное окно MVP и deterministic tie-break

**Context.** Голосование должно быть после фактического окончания и завершаться автоматически.

**Decision.** Для достаточного состава участие награждается один раз после finish, voting открывается до `end + 3 minutes`, затем MVP выбирается по vote count и UUID при tie.

**Reason.** Исправляет противоречивое исходное состояние и делает processing повторяемым/tests deterministic.

**Consequences.** Окно короткое и подходит demo, но может быть неудобно реальным игрокам. Изменение duration требует migration и синхронизации UI/docs/tests.

## ADR-010 — Realtime как сигнал обновления, а не локальное применение событий

**Context.** Composite RPC models содержат joins/counts/highlights, которые сложно корректно обновлять одним row payload.

**Decision.** Realtime event служит сигналом повторно вызвать authoritative query/RPC.

**Reason.** Простота и корректность текущего масштаба.

**Consequences.** Больше network requests; UI получает согласованный snapshot. При росте нагрузки потребуется debounce/coalescing или более точечные updates.

## ADR-011 — уникальный канал Realtime для каждого экземпляра

**Context.** Общий channel name и регистрация callback после subscribe создавали order-dependent test/runtime failure.

**Decision.** Каждый realtime service создаёт уникальный channel, регистрирует handlers до subscribe и удаляет channel при cleanup.

**Reason.** Изоляция lifecycle экранов и повторных tests.

**Consequences.** Нет конфликтов shared channel; важно сохранять unsubscribe в `deinit` и не создавать лишние долгоживущие ViewModels.

## ADR-012 — фиксированный путь аватара и upsert

**Context.** Upload `{userId}/avatar.jpg` без upsert ломал повтор после частичного сбоя.

**Decision.** Один fixed object per user, client resize до 1024 px/JPEG <= 5 MiB, `upsert:true`, cache-busting URL; owner-folder policies.

**Reason.** Retry safety и отсутствие orphaned avatar versions.

**Consequences.** Простое удаление и quota; история фотографий не хранится; CDN cache обходится query parameter.

## ADR-013 — публичное скачивание аватаров из bucket

**Context.** Roster/profile UI должен показывать avatars по обычному URL. Изначальный bucket уже был public.

**Decision.** Сохранить public download, но закрыть listing/metadata/write/delete owner policies.

**Reason.** Минимальная совместимость с существующей моделью `avatar_url` и portfolio scope.

**Consequences.** Знающий object URL может скачать avatar. Для строгой приватности нужны private bucket и signed URLs; Privacy Policy не должна обещать абсолютную приватность URL.

## ADR-014 — удаление аккаунта через Edge Function

**Context.** Auth Admin delete и service-role data cleanup нельзя выполнять из iOS.

**Decision.** JWT-protected DELETE Edge Function получает user ID только из verified claims, вызывает service-only SQL cleanup и Auth Admin delete.

**Reason.** Выполнить App Store account deletion без service key в client.

**Consequences.** Есть отдельный deployable artifact. Shared games сохраняются с nullable creator; partial external steps должны быть retry-safe.

## ADR-015 — сохранить shared match history при удалении аккаунта

**Context.** Полное удаление созданных games уничтожило бы историю других участников.

**Decision.** Обнулить `games.creator_id`, удалить персональные membership/votes/stats/reviews/profile и пересчитать park aggregates.

**Reason.** Баланс удаления персональной связи и целостности shared data.

**Consequences.** Game остаётся без creator. `games.creator_id`, контракты list RPC и Swift `Game.creatorId` допускают `NULL`/`nil`. Park Details, My Games, Game Details и Recent Matches продолжают показывать сохранённую игру оставшимся участникам.

## ADR-016 — email/password только для версии 1.0

**Context.** Sign in with Apple был видимым, но disabled; полноценный OAuth не реализован.

**Decision.** Удалить Apple sign-in из 1.0, оставить рабочий email/password и recovery.

**Reason.** Не обещать App Review недоступную функцию и не расширять portfolio scope.

**Consequences.** Меньше auth surface; Apple login можно вернуть только полноценной отдельной задачей.

## ADR-017 — custom URL scheme для Auth callbacks

**Context.** Native app должен получить confirmation/recovery PKCE callback.

**Decision.** `gamespot://auth/confirmed` и `gamespot://auth/recovery`, routing по scheme/host/path, session exchange через Supabase SDK.

**Reason.** Минимальный native flow без отдельного universal-link domain.

**Consequences.** URL must be allow-listed в hosted Supabase. Custom schemes могут быть заявлены другим app; PKCE/token verification остаётся обязательным. Universal Links были бы сильнее для развитого продукта.

## ADR-018 — единый user-safe content state

**Context.** Ошибки выглядели как empty content или raw `localizedDescription`.

**Decision.** Общий `ContentStateView`, отдельные loading/error/empty values и Retry на reviewer journey.

**Reason.** Предсказуемость UI и отсутствие технических details.

**Consequences.** Единый стиль и test IDs; ViewModels должны поддерживать явный state и cancellation paths.

## ADR-019 — on-device location и внешний weather без API key

**Context.** Карта должна показывать позицию, Game Info — forecast.

**Decision.** Core Location when-in-use остаётся на устройстве; Open-Meteo получает только координаты выбранного park/time.

**Reason.** Фактический код и минимальная privacy/data surface. Первоначальная причина выбора Open-Meteo не зафиксирована.

**Consequences.** Нет background tracking и location rows в backend; нужен internet; forecast range ограничен; availability зависит от внешнего provider.

## ADR-020 — portfolio scope важнее масштабирования

**Context.** Текущая цель — законченное приложение для портфолио, а не startup growth.

**Decision.** Не добавлять monetization, analytics, speculative infrastructure, broad refactors и high-load optimization без release blocker.

**Reason.** Сохранить понятный, проверяемый scope и сосредоточить проект на демонстрации iOS/backend engineering.

**Consequences.** Дальнейшее развитие должно начинаться с нового аудита требований и нагрузки, а не с предположения, что portfolio-архитектура уже готова к масштабу.
