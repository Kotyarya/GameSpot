# Running GameSpot on a New Mac

This guide is written for someone opening the project for the first time. It contains no secret values.

## Requirements

- macOS capable of running Xcode 26;
- Xcode 26.4 or newer; this documentation was checked with Xcode 26.6;
- an iOS 26 Simulator runtime;
- Git;
- internet access for Swift Package Manager, Supabase, and Open-Meteo;
- for the local backend: a Docker-compatible runtime, Supabase CLI, and `psql`;
- for a physical iPhone: an Apple ID/Development Team and a suitable provisioning profile.

A paid Apple Developer account is not required for the Simulator. The app target uses Swift 6.0, has a minimum deployment target of iOS 26.0, and uses the bundle ID `com.kotyarya.GameSpot`. Test targets use Swift 5 language mode.

## Get the Code

```bash
git clone https://github.com/Kotyarya/GameSpot.git
cd GameSpot
```

The current portfolio version is stored in `main`; no feature-branch checkout is required.

Check the repository state:

```bash
git status --short --branch
git rev-parse HEAD
```

## Open the Xcode Project

```bash
open "Game Spot.xcodeproj"
```

The repository does not use a separate workspace. Swift Package Manager resolves `supabase-swift` automatically; `Package.resolved` pins version 2.44.1 and its transitive dependencies.

In Xcode, select the `Game Spot` scheme and any available iOS 26 or newer simulator, then press Run (`⌘R`). List available devices with `xcrun simctl list devices available`.

## Client Configuration

The application expects two bundle keys in `Game-Spot-Info.plist`:

- `SupabaseURL`;
- `SupabasePublishableKey`.

For another environment, obtain the Project URL and an active publishable or legacy anon key from Supabase Dashboard → Project Settings/API. Never put server-side credentials in the client configuration.

Never add the following to the iOS app or Git:

- a service-role key;
- a key in the `sb_secret_...` format;
- a database password;
- a Supabase personal access token;
- a JWT signing key;
- test-account credentials.

`AppConfiguration` requires an HTTPS URL and a non-empty publishable key. The app intentionally fails at startup when configuration is invalid so a broken build cannot be mistaken for a working one.

The project could use `.xcconfig` files for more advanced environment separation in the future; the current implementation reads Info.plist.

## Custom URL Scheme and Authentication

Info.plist registers the `gamespot` scheme. The client expects these exact routes:

- `gamespot://auth/confirmed`;
- `gamespot://auth/recovery`.

They are defined in `supabase/config.toml` for local Supabase. For a hosted project, add them manually under Auth → URL Configuration → Redirect URLs. Avoid wildcard redirects unless there is a specific reason to use one.

Production email sign-up currently uses automatic confirmation. Both exact redirect URLs are present in the hosted allow-list and have been verified.

## Run in the Simulator

Command-line build:

```bash
xcodebuild build \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=<available simulator name>'
```

If the requested simulator is unavailable:

```bash
xcrun simctl list devices available
```

Use the exact name of an installed device. To verify the location flow from a clean state, delete the app or reset its privacy permission before launching it.

## Run on a Physical iPhone

1. Connect the iPhone and trust the Mac.
2. Select your Development Team under the app target's Signing & Capabilities settings.
3. If the bundle ID conflicts, change it only in your local development configuration.
4. Enable Developer Mode on the iPhone if Xcode requests it.
5. Select the device and press Run.

A free Personal Team is sufficient for local runs, subject to Apple's limitations. TestFlight and App Store distribution are outside the current portfolio scope.

## Unit Tests

```bash
xcodebuild test \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -destination 'platform=iOS Simulator,name=<available simulator name>' \
  -only-testing:'Game SpotTests'
```

The unit suite uses service and Realtime doubles and must not modify production Supabase. The configuration test checks only the shape of the client URL and publishable key.

## UI Tests

Run the complete UI target with:

```bash
xcodebuild test \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -destination 'platform=iOS Simulator,name=<available simulator name>' \
  -only-testing:'Game SpotUITests'
```

Most tests use a DEBUG-only harness and require no account. Authenticated tests run only when a fully onboarded, isolated test account is available. Pass credentials through the environment of an already running simulator because the UI-test runner does not inherit arbitrary shell variables from `xcodebuild`:

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

Replace `-only-testing` with another authenticated test when needed, for example `Game SpotUITests/AuthFlowUITests/testAuthenticatedUserCanOpenPrivacyPolicy`. Never store credentials in a scheme, shell history, Git, or documentation. Use an isolated test account and delete it after verification.

## Unsigned Release Build

```bash
xcodebuild build \
  -project "Game Spot.xcodeproj" \
  -scheme "Game Spot" \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO
```

An unsigned Release Simulator build is sufficient for portfolio verification. Signing and archiving are required only if App Store distribution is approved later.

## Local Supabase

### Installation

Install the current Supabase CLI using its official instructions, a Docker-compatible runtime such as Docker Desktop or Colima, and the PostgreSQL client. Verify the tools:

```bash
supabase --version
docker --version
psql --version
```

When using Colima:

```bash
colima start
docker info
```

### Clean Schema Reset

From the repository root:

```bash
supabase start
supabase db reset --local --no-seed
```

This applies the complete versioned migration history to the local database. Never reset the hosted production project.

### SQL Regression Suite

```bash
DATABASE_URL='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
for test_file in supabase/tests/database/*.sql; do
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$test_file"
done
```

Every script should exit successfully. Tests use assertions and roll back any test data they create.

### Schema Diff

```bash
supabase db diff --local --schema public,storage
```

No schema changes are expected after a clean reset. Stop the local stack with:

```bash
supabase stop
```

## Run the Edge Function Locally

The source is in `supabase/functions/delete-account/`. The function requires the Supabase runtime and a valid JWT. Never place a service-role key in the client. Use a Deno version compatible with the lockfile for type and format checks. Production deployment requires separate approval.

## Recommended Workflow Before Changing Code

1. Create a separate branch and confirm that the working tree is clean.
2. For Swift changes: focused tests → complete unit suite → relevant UI tests → Release build.
3. For SQL changes: new migration → clean reset → all SQL regression tests → schema diff → advisor review.
4. Never store credentials, production user data, or server-side secrets in Git.

## Troubleshooting

### Swift Package Manager Cannot Resolve Packages

Check internet access, then use File → Packages → Reset Package Caches or Resolve Package Versions. Do not delete `Package.resolved` without a reason.

### Simulator Not Found

Install the iOS 26 runtime under Xcode Settings → Platforms and use a device name returned by `simctl list`.

### App Crashes Immediately

Check the two Info.plist configuration keys. Never replace the publishable key with a service-role key.

### Recovery Link Opens a Browser or Invalid Screen

Check the custom scheme in the built Info.plist and both exact hosted Redirect URLs. Wildcard redirects are not used.

### Local Supabase Does Not Start

Check the Docker context/runtime, confirm that ports 54320–54324 are available, and verify that the database major version is 17.
