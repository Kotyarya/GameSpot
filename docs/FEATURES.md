# Реализованные функции GameSpot

Документ описывает текущие пользовательские сценарии и задействованные компоненты. Он не является списком будущих идей.

## Authentication

### Sign up

1. Пользователь вводит email/password в `AuthView`.
2. `AuthViewModel` нормализует email и вызывает `AuthService.signUp`.
3. Supabase Auth возвращает user и, в зависимости от настройки confirmation, session.
4. Если session есть, `SessionManager.refreshUser()` загружает profile.
5. Если session нет, UI показывает Check your email и Resend.
6. Confirmation deep link `gamespot://auth/confirmed` обрабатывает `AuthLinkCoordinator`; после PKCE session exchange profile загружается заново.

Production сейчас использует auto-confirm, поэтому обычная регистрация сразу создаёт session. Код confirmation сохранён для корректности при будущей смене настройки.

### Sign in / sign out

Sign in выполняет Supabase email/password Auth, затем `SessionManager` выбирает onboarding/profile setup/main по profile flags. Sign out очищает Supabase и локальное состояние. Технические Auth errors не показываются дословно.

Sign in with Apple в версии 1.0 отсутствует: прежняя неработающая кнопка удалена.

### Password recovery

1. Forgot password открывает `PasswordResetRequestView`.
2. `resetPasswordForEmail` отправляет письмо с redirect `gamespot://auth/recovery`.
3. UI всегда показывает нейтральный результат и не раскрывает существование email.
4. Deep link обменивается на temporary recovery session.
5. `PasswordRecoveryView` проверяет те же password rules, что registration, и вызывает Auth update.
6. После успеха recovery session закрывается; пользователь возвращается к Sign In.

Локальный код и tests готовы. Hosted redirect allow-list ещё не содержит два custom URL, поэтому production E2E отложен; см. [TODO.md](TODO.md).

## Onboarding и Profile Setup

После первого входа backend profile создаётся trigger автоматически.

1. Если `is_onboarded=false`, `RootView` показывает carousel.
2. Первый Continue запрашивает foreground location permission.
3. Завершение обновляет `profiles.is_onboarded` и перечитывает session.
4. Если `is_profile_completed=false`, открывается Profile Setup.
5. Загружается список sports; username проверяется после debounce; пользователь выбирает favorite sport и optional photo.
6. Avatar уменьшается/сжимается и upsert-ится в Storage.
7. Safe profile columns обновляются; только после полного успеха session перечитывается.

Partial avatar upload не блокирует retry: повторный upsert заменяет тот же объект. UI отдельно показывает load/error/retry для sports и submit.

## Map и геолокация

`MapViewModel` загружает активные `parks`. `MapView` показывает MapKit markers и current device position при разрешении пользователя. Выбор marker открывает park sheet.

Location используется только локально для позиции пользователя. Координаты устройства не записываются в Supabase и не отправляются в Open-Meteo. Open in Maps передаёт координаты выбранного park системному приложению Maps.

Если parks не загрузились, пользователь видит понятный error и Try Again; пустой catalog имеет отдельное empty state.

## Park details и поиск площадок

Отдельной текстовой строки поиска нет. «Поиск» в текущей реализации — визуальный выбор active park на карте.

После выбора `ParkDetailsViewModel` параллельно загружает:

- основные поля park;
- доступные sports;
- weekly hours;
- image URLs;
- aggregate rating.

UI показывает lighting, open/closed, photos, rating и actions View Games/Create Game. Protection по requested park ID не даёт старому async response перезаписать новый выбор.

## Rating площадки

Авторизованный пользователь выставляет quality/facilities/activity от 1 до 5. `rate_park` проверяет identity и range, создаёт или обновляет один review на user+park и полностью пересчитывает aggregate `parks_ratings`. Double submit блокируется, failure остаётся на форме и допускает retry.

## Create Game

1. Из park details пользователь выбирает Create Game.
2. `CreateGameView` предлагает только sports, связанные с park.
3. Пользователь выбирает sport и start time.
4. `CreateGameViewModel` проверяет выбор и вызывает `create_game`.
5. Server проверяет auth, будущее время, связь park/sport и отсутствие пересечения игр.
6. Duration и capacity берутся из `sports`, а не из клиента.
7. Game создаётся вместе с creator membership в Team Alpha.
8. После успеха открывается Game Info.

Server является источником истины; подмена creator/duration/capacity прямым table write запрещена.

## Games list / My Games

`GamesView` работает в двух режимах:

- `.myGames` вызывает `get_user_games()`;
- `.park(id)` вызывает `get_games_by_park(id)`.

`GameSectionBuilder` группирует по календарному дню, сортирует sections/games и строит Today/Tomorrow/Yesterday или локализованную дату. `Calendar`, `now`, `Locale` можно внедрить в tests.

Realtime changes в `games` или `game_members` запускают reload текущего режима. Error и empty states различаются: My Games подсказывает найти/создать игру, сетевой error предлагает Retry.

## Game Info

`get_game_details` возвращает один составной payload: состояние, park, sport, roster, current membership/vote, player highlights и MVP. Параллельно после details запрашивается weather.

Weather — optional: ошибка Open-Meteo не скрывает game data. Пользователь видит Refresh вместо ложных 0°C/0%.

Экран показывает upcoming countdown, live state, Voting, Finished или Completed согласно backend flags.

## Join Game

1. Пользователь открывает team sheet.
2. Выбирает свободный slot Team Alpha/Beta.
3. Sheet устанавливает submitting state и блокирует повторный tap/закрытие.
4. `join_game` блокирует game row и проверяет pre-start state, duplicate и team capacity.
5. После успеха details перечитываются, sheet закрывается.
6. При ошибке sheet остаётся открытым и показывает безопасное сообщение.

## Leave Game

Путь аналогичен Join. `leave_game` удаляет только membership текущего `auth.uid()` и только до старта. Creator также может выйти до старта; сама game остаётся существовать. После успеха details перечитываются.

## Жизненный цикл матча

State меняет server cron, не открытый client timer:

1. Scheduled — Join/Leave доступны.
2. In Progress — начинается в первую минутную итерацию после `starts_at`.
3. Finished — после configured duration.
4. Если участников меньше `minimum_players_for_rewards`, game становится Processed без rewards.
5. Иначе participation rewards выдаются один раз, открывается MVP Voting на 3 минуты.
6. После окна выбирается MVP, выдаётся bonus и game становится Processed.

UI timer только отображает время; даже изменённые часы устройства не обходят backend rules.

## MVP voting

Голосовать может только participant завершённой game во время открытого window. Нельзя голосовать за себя, неучастника или повторно. За сам vote текущий пользователь получает 2 global performance points; MVP получает global и per-sport bonus, зависящий от количества votes. Итог сохраняется также в `game_members` для recent match history.

## Жалобы и блокировка пользователей

Game Info показывает список игроков. Выбор другого игрока открывает публичный
профиль с рейтингом, количеством игр, Report User и Block User.

Report позволяет выбрать причину и добавить до 500 символов контекста. Повторная
жалоба на того же пользователя с той же причиной не создаёт duplicate и не
раскрывает внутреннее состояние модерации. Block требует подтверждения, после
успеха сразу скрывает игрока из roster, teams, highlights, MVP voting и MVP card.

Profile → Blocked Users показывает приватный список и позволяет выполнить
Unblock. Username проверяется сервером на длину, допустимые символы, reserved
names и минимальный offensive-word deny-list. Ручной процесс владельца описан в
[MODERATION.md](MODERATION.md).

## Profile и Statistics

Profile параллельно загружает:

- `profiles` с favorite sport;
- все `user_sport_stats`;
- три последних завершённых матча через RPC.

Показываются global rating/games/MVP/performance points, per-sport cards, league/division Bronze → King и recent changes. Realtime updates profile/stats и перечитывает recent matches.

Расчёт league/division выполняет `RankHelper` в клиенте; числовую статистику изменяет только backend.

## Avatar

Пользователь может добавить, заменить или удалить photo и при initial setup, и в готовом profile. Client создаёт JPEG не более 1024 px и 5 MiB, загружает в `{userId}/avatar.jpg` с upsert. URL получает cache-busting query. Storage policies разрешают управление только owner folder.

Bucket public для отображения URL другим signed-in пользователям; знание URL технически позволяет public download.

## Weather

`WeatherService` вызывает бесплатный Open-Meteo forecast API по координатам park и выбирает hourly value, ближайшее к `starts_at`. Показываются temperature, wind и precipitation probability. API key не нужен. Forecast ограничен запрашиваемыми семью днями, поэтому слишком далёкая game получит ближайшее доступное значение — известное ограничение.

## Realtime updates

Realtime не заменяет database reads: событие уведомляет ViewModel, после чего authoritative state перечитывается.

- game lists: `games`, `game_members`;
- game info: `games`, `game_members`, `game_mvp_votes`, с фильтром game ID;
- profile: `profiles`, `user_sport_stats`, с фильтром user ID.

Channels уникальны для экземпляра экрана и удаляются при cleanup, что устраняет прежние order-dependent failures.

## Privacy и удаление аккаунта

Privacy Policy доступна из Profile и публично по <https://kotyarya.github.io/GameSpot/>. Profile содержит необратимое Delete Account с двойным подтверждением.

Edge Function проверяет JWT, удаляет avatar, application data и Auth user. При ошибке app не имитирует успех и сохраняет session для Retry. Подробнее: [DATABASE.md](DATABASE.md) и [privacy-policy.md](privacy-policy.md).

## Что намеренно отсутствует в версии 1.0

- Sign in with Apple;
- push notifications;
- offline cache;
- payments/ads/analytics;
- background location;
- полноценный park text search;
- admin UI для parks/sports.

Отсутствие функции не считается багом, если она не обещана в App Store metadata.
