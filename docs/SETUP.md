# Запуск GameSpot на новом Mac

Инструкция рассчитана на человека, который раньше не открывал проект. Она не содержит секретных значений.

## Требования

- macOS, поддерживающая Xcode 26;
- Xcode 26.4 или новее; документация проверялась с Xcode 26.6;
- установленный runtime симулятора iOS 26 или новее;
- Git;
- интернет для Swift Package Manager, Supabase и Open-Meteo;
- для локального backend: совместимый с Docker runtime, Supabase CLI, `psql`;
- для физического iPhone: Apple ID/Development Team и подходящий provisioning profile;
- для запуска на физическом устройстве достаточно подходящей Development Team; для Simulator платный Apple Developer account не нужен.

Настройки проекта: основной target использует Swift 6.0, минимальная версия системы — iOS 26.0, bundle ID — `com.kotyarya.GameSpot`. Тестовые targets используют режим языка Swift 5.

## Получить код

```bash
git clone https://github.com/Kotyarya/GameSpot.git
cd GameSpot
```

Актуальная портфолио-версия находится в ветке `main`; переключаться на feature-ветку не требуется.

Проверьте состояние:

```bash
git status --short --branch
git rev-parse HEAD
```

## Открыть Xcode project

```bash
open "Game Spot.xcodeproj"
```

Workspace отдельно не создавался. Swift Package Manager автоматически разрешит `supabase-swift`; lockfile фиксирует версию 2.44.1 и transitive dependencies.

В Xcode выберите схему `Game Spot`, любой доступный симулятор с iOS 26 или новее, затем нажмите Run (`⌘R`). Точный список доступных устройств можно получить командой `xcrun simctl list devices available`.

## Конфигурация клиента

Приложению нужны два bundle keys в `Game-Spot-Info.plist`:

- `SupabaseURL`;
- `SupabasePublishableKey`.

Для своего окружения получите Project URL и активный publishable/legacy anon key в Supabase Dashboard → Project Settings/API. Не используйте серверные credentials в конфигурации клиента.

Никогда не добавляйте в iOS или Git:

- ключ service-role;
- ключ формата `sb_secret_...`;
- пароль базы данных;
- персональный access token Supabase;
- ключ подписи JWT;
- пароль тестового аккаунта.

`AppConfiguration` требует HTTPS URL и непустой publishable key. При ошибке configuration приложение намеренно падает на старте, чтобы неверная сборка не маскировалась.

Для более удобного разделения environments в будущем можно подключить `.xcconfig`, но текущая реализация читает Info.plist.

## Custom URL scheme и Auth

Info.plist регистрирует scheme `gamespot`. Клиент ожидает exact routes:

- `gamespot://auth/confirmed`;
- `gamespot://auth/recovery`.

Для локального Supabase они записаны в `supabase/config.toml`. Для hosted проекта их необходимо вручную добавить в Auth → URL Configuration → Redirect URLs. Не используйте wildcard, если нет отдельной причины.

Production email signup сейчас auto-confirm. Оба exact redirect URL добавлены в hosted allow-list и проверены.

## Запуск в Simulator

CLI-вариант:

```bash
xcodebuild build \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Если конкретного Simulator нет:

```bash
xcrun simctl list devices available
```

Подставьте точное имя доступного устройства. Для чистой проверки location удалите приложение или сбросьте privacy permission перед запуском.

## Запуск на физическом iPhone

1. Подключите iPhone и доверьте Mac.
2. В target Signing & Capabilities выберите свой Development Team.
3. При конфликте замените bundle ID на уникальный только в своей локальной development configuration.
4. Включите Developer Mode на iPhone, если Xcode попросит.
5. Выберите устройство и Run.

Бесплатный personal team подходит для локального запуска с ограничениями. TestFlight/App Store не входят в текущий portfolio scope.

## Unit-тесты

```bash
xcodebuild test \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -destination 'platform=iOS Simulator,name=<имя доступного симулятора>' \
  -only-testing:'Game SpotTests'
```

Unit suite использует service/realtime doubles и не должна изменять production Supabase. Configuration test только проверяет форму client URL/publishable key.

## UI-тесты

Весь UI target:

```bash
xcodebuild test \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:'Game SpotUITests'
```

Большинство tests используют DEBUG-only harness и не требуют account. Authenticated tests выполняются только при наличии полностью onboarded isolated test account. Передавайте credentials через временное окружение уже запущенного симулятора, потому что UI-test runner не наследует произвольные shell variables от `xcodebuild`:

```bash
read -r 'GAMESPOT_UI_TEST_EMAIL?Test email: '
read -rs 'GAMESPOT_UI_TEST_PASSWORD?Test password: '
echo
GAMESPOT_SIMULATOR_UDID='<Simulator UDID from Xcode>'

xcrun simctl boot "$GAMESPOT_SIMULATOR_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$GAMESPOT_SIMULATOR_UDID" -b
xcrun simctl spawn "$GAMESPOT_SIMULATOR_UDID" launchctl setenv \
  GAMESPOT_UI_TEST_EMAIL "$GAMESPOT_UI_TEST_EMAIL"
xcrun simctl spawn "$GAMESPOT_SIMULATOR_UDID" launchctl setenv \
  GAMESPOT_UI_TEST_PASSWORD "$GAMESPOT_UI_TEST_PASSWORD"

xcodebuild test \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -destination "platform=iOS Simulator,id=$GAMESPOT_SIMULATOR_UDID" \
  -only-testing:'Game SpotUITests/NavigationFlowUITests/testMainTabBarVisibleWhenAuthenticated'

xcrun simctl spawn "$GAMESPOT_SIMULATOR_UDID" launchctl unsetenv \
  GAMESPOT_UI_TEST_EMAIL
xcrun simctl spawn "$GAMESPOT_SIMULATOR_UDID" launchctl unsetenv \
  GAMESPOT_UI_TEST_PASSWORD
unset GAMESPOT_UI_TEST_EMAIL GAMESPOT_UI_TEST_PASSWORD \
  GAMESPOT_SIMULATOR_UDID
```

При необходимости замените `-only-testing` на другой authenticated test, например `Game SpotUITests/AuthFlowUITests/testAuthenticatedUserCanOpenPrivacyPolicy`. Не записывайте credentials в scheme, shell history, Git или документацию. Используйте изолированный test account и удаляйте его после проверки.

## Release-сборка без подписи

```bash
xcodebuild build \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

Для portfolio-проверки достаточно успешной Release Simulator сборки. Подпись и archive нужны только если позже будет принято отдельное решение о публикации.

## Локальный Supabase

### Установка

Установите актуальный Supabase CLI официальным способом, Docker/Colima и PostgreSQL client. Проверьте:

```bash
supabase --version
docker --version
psql --version
```

Если используется Colima:

```bash
colima start
docker info
```

### Чистое восстановление схемы

Из корня репозитория:

```bash
supabase start
supabase db reset --local --no-seed
```

Это применит всю versioned migration history к локальной базе. Никогда не запускайте reset для hosted production.

### Набор SQL regression tests

```bash
DATABASE_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
for test_file in supabase/tests/database/*.sql; do
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$test_file"
done
```

Ожидается успешный выход всех scripts. Они сами используют assertions и rollback там, где создают test data.

### Проверка отличий схемы

```bash
supabase db diff --local --schema public,storage
```

После clean reset ожидается отсутствие schema changes. Остановить stack:

```bash
supabase stop
```

## Edge Function локально

Исходник находится в `supabase/functions/delete-account/`. Function требует Supabase runtime и JWT. Не подставляйте service role вручную в client. Для type/format checks используйте Deno версии, совместимой с lockfile. Deploy в production допускается только как отдельное подтверждённое действие.

## Полезная последовательность перед изменением кода

1. Создать отдельную ветку и убедиться, что рабочая копия чистая.
2. Для Swift: focused tests → полный unit suite → relevant UI → Release build.
3. Для SQL: новая migration → clean reset → все SQL regression tests → schema diff → advisor review.
4. Не сохранять credentials, production user data или server-side secrets в Git.

## Частые проблемы

### SPM не разрешает packages

Проверьте internet, затем File → Packages → Reset Package Caches/Resolve Package Versions. Не удаляйте `Package.resolved` без причины.

### Simulator не найден

Установите iOS 26 runtime в Xcode Settings → Platforms и подставьте имя из `simctl list`.

### App падает сразу

Проверьте два Info.plist configuration keys. Не заменяйте publishable key service-role key.

### Ссылка восстановления открывает браузер или некорректный экран

Проверьте custom scheme в собранном Info.plist и оба exact hosted Redirect URLs. Wildcard redirects не используются.

### Local Supabase не стартует

Проверьте Docker context/runtime, свободны ли порты 54320–54324, и соответствует ли database major version 17.
