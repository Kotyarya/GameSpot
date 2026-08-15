# GameSpot App Store Privacy Checklist

Prepared: August 15, 2026

This checklist maps the current iOS code and versioned Supabase schema to the
answers that should be entered in App Store Connect. Recheck it against the
archive before submission.

## App Privacy answers

GameSpot collects data, so **Data Not Collected** must not be selected.

All categories below are linked to the user's identity, used for **App
Functionality**, and are **not used for tracking**.

| App Store data type | GameSpot data | Collected | Linked | Tracking | Purpose |
| --- | --- | --- | --- | --- | --- |
| Contact Info → Email Address | Supabase Auth email | Yes | Yes | No | App Functionality |
| Identifiers → User ID | Auth/profile UUID | Yes | Yes | No | App Functionality |
| User Content → Photos or Videos | Optional profile avatar | Yes | Yes | No | App Functionality |
| User Content → Other User Content | Username and park reviews/ratings | Yes | Yes | No | App Functionality |
| User Content → Gameplay Content | Games, teams, match history, stats, and MVP votes | Yes | Yes | No | App Functionality |
| Location → Coarse Location | Country derived from IP in Supabase service logs | Yes | Yes | No | App Functionality |
| Diagnostics → Other Diagnostic Data | IP address, user-agent, request timestamp, route, and response status in Supabase logs | Yes | Yes | No | App Functionality |

Do not select advertising, developer marketing, third-party advertising,
analytics, or tracking purposes for the current build.

## Data that is not collected by GameSpot

- **Precise Location:** MapKit/Core Location uses the GPS position only on
  the device. The iOS code does not upload it or derive a location value sent to
  Supabase. This is different from the coarse country that Supabase may derive
  from an IP address in service logs. Apple states that data processed only on
  the device is not collected for App Privacy disclosures.
- **Product analytics and crash reports:** the project contains no analytics,
  attribution, advertising, or crash-reporting SDK. Supabase technical request
  logs are disclosed separately above as Other Diagnostic Data.
- **Financial, health, contacts, browsing, and search data:** no related feature
  or backend column exists.

## Data map

| Data | Source | Storage/processor | Visibility | Deletion behavior |
| --- | --- | --- | --- | --- |
| Email address | Sign up/sign in | Supabase Auth | Account owner and backend auth service | Auth user deleted |
| User ID | Supabase Auth | Auth and public app tables | Used internally; profile linkage visible to authenticated features | Deleted or unlinked with account |
| Username | Profile setup | `public.profiles` | Other signed-in users | Profile deleted |
| Avatar | Photo picker | Supabase Storage `avatars` and URL in `public.profiles` | Other signed-in users | Storage object and profile deleted |
| Favorite sport/profile progress | Profile setup/app activity | `public.profiles`, `public.user_sport_stats` | Signed-in app features | Deleted with profile |
| Gameplay content | Create/join/play/vote | `public.games`, `public.game_members`, `public.game_mvp_votes`, `public.user_sport_stats` | Participants and signed-in app features | Membership/votes/stats deleted; creator reference unlinked where a game remains |
| Park rating/review | Park details | `public.parks_ratings`, `public.park_reviews` | Aggregate rating and reviews in signed-in app | Review deleted; numeric rating may be anonymized for aggregates |
| Precise device location | iOS permission + MapKit | On-device only | User only | Not retained by GameSpot |
| Network and diagnostic metadata | Requests to Supabase | Supabase service logs | GameSpot operator and service provider | Retained according to the project's Supabase plan and provider schedule |

## Privacy manifest and required-reason API review

- The GameSpot Swift source does not directly call UserDefaults, file timestamp,
  disk-space, system boot-time, or active-keyboard APIs from Apple's current
  required-reason categories.
- The current Supabase Swift dependency is pinned in `Package.resolved`; its
  storage code reads an uploaded file's size, not timestamps. The transitive
  Swift Crypto package includes its own privacy manifests.
- Therefore the app does not currently need its own `PrivacyInfo.xcprivacy` for
  a required-reason API. Do not add an empty or speculative manifest.
- Before submission, create Xcode's privacy report from the final archive and
  resolve every warning from App Store Connect. Add an app privacy manifest only
  if the final code or report identifies an app-owned declaration.

## Final release gates

- [ ] Replace `{{SUPPORT_CONTACT}}` in `docs/privacy-policy.md` with a monitored
  public support email or URL approved by the owner.
- [ ] Publish the completed policy at a stable public HTTPS URL.
- [ ] Put that URL in App Store Connect and verify it without authentication.
- [ ] Confirm the same support contact in App Store Connect.
- [ ] Generate and inspect Xcode's privacy report from the final archive.
- [ ] Recheck disclosures after any SDK or feature change.

## Authoritative references

- [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Describing data use in privacy manifests](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests)
- [Describing use of required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
