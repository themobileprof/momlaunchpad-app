# GA4 analytics (Firebase) — MomLaunchpad

This app sends product analytics to **Google Analytics 4** via **Firebase Analytics**. The code lives behind `AnalyticsService` so you can swap providers later if needed.

## GA4 vs admin console (`momlaunchpad-admin`)

Use **both** — they answer different questions:

| Metric | GA4 (mobile) | Admin web (`/console`) |
|--------|----------------|-------------------------|
| DAU / WAU / retention | Yes — Engagement & Retention reports | No — dashboard “active” = users who **chatted**, not full app DAU |
| Most-used features | Yes — `feature_used`, `tab_selected` | Partial — chat quota / topic volume only |
| AI question **topics** | Yes — `ai_question_sent` buckets (no raw text) | Yes — **Top chat topics** with **sample questions** |
| User **testimonials** (full text) | No — rating metadata only | Yes — **Feedback** page (`GET /api/admin/analytics/feedback`) |
| User counts by plan | No | Yes — Dashboard |
| Referrals / community mod | No | Yes — dedicated admin pages |

**Rule:** Anything with **PII**, **health content**, or **long-form quotes** stays on the **admin console** (your API + DB). GA4 gets **aggregates and enums** only.

## One-time Firebase setup

1. Create a project at [Firebase Console](https://console.firebase.google.com).
2. Add an **Android** app with package `com.momlaunchpad.app`.
3. Download `google-services.json` → `android/app/google-services.json`.
4. (Optional, for iOS) Add iOS app → `ios/Runner/GoogleService-Info.plist`.
5. Enable **Google Analytics** when prompted (creates a GA4 property).

### FlutterFire configure

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then in `lib/firebase_options.dart` set:

```dart
static const bool enabled = true;
```

### Release builds

In `.env` or GitHub `ENV_FILE`:

```
FIREBASE_ANALYTICS_ENABLED=true
```

Debug builds default to **off** unless you set `FIREBASE_ANALYTICS_ENABLED=true`.

---

## What each metric uses

| Goal | GA4 source | App events / data |
|------|------------|-------------------|
| **DAU / WAU** | Reports → Engagement → Users | `app_open`, `screen_view`, `feature_used`, `setUserId` after login |
| **Retention** | Reports → Retention | Same events + stable `user_id` (internal UUID) |
| **Most-used features** | Explore → Events → `feature_used` | Param `feature_name`: `home`, `chat`, `community`, `calendar`, `community_post`, … |
| **AI questions** | Event `ai_question_sent` | Params `topic_bucket`, `intent_category`, `message_length_bucket` — **no raw chat text** |
| **Testimonials** | Event `testimonial_submitted` | Params `rating`, `has_written_feedback`, `source` |
| **Full testimonial text** | Not in GA4 | Admin → **Feedback** (`/console/feedback`) or `GET /api/admin/analytics/feedback` |

### AI question topics (GA4)

Client buckets messages locally (`lib/utils/analytics_topic_classifier.dart`), aligned with backend admin topic analytics.

For **sample quotes** and deeper NLP, use:

- `GET /api/admin/analytics/topics?days=30` (server-side; includes `sample_query`)

**Do not** send full chat content to Firebase (health data + policy risk).

---

## GA4 console — where to click

### Daily / weekly active users

1. [analytics.google.com](https://analytics.google.com) → your GA4 property.
2. **Reports → Engagement → Overview** — Active users (1 day / 7 days / 28 days).
3. Or **Explore → Free form**: Dimension `Date`, Metric `Active users`.

### Retention

1. **Reports → Retention** (or **Explore → Retention** template).
2. Needs ~2 weeks of data for meaningful curves.

### Most-used features

1. **Explore → Free form**.
2. Rows: `Event name` = `feature_used`.
3. Breakdown: `feature_name` custom parameter (register as custom dimension in GA4 Admin if needed).
4. Also analyze `tab_selected` → `tab_name`.

### AI questions

1. **Explore → Free form**.
2. Filter: Event = `ai_question_sent`.
3. Breakdown: `topic_bucket`, `intent_category`.

Register custom dimensions (GA4 Admin → Custom definitions):

- `feature_name`
- `topic_bucket`
- `intent_category`
- `tab_name`

### Testimonials

1. **Explore → Events** → `testimonial_submitted`.
2. Breakdown: `rating`.
3. Read full quotes: `GET /api/admin/analytics/feedback` (admin API).

---

## Events reference

| Event | When |
|-------|------|
| `app_open` | App resumed (max once per 30 min) |
| `login_success` | Email or Google login |
| `signup_complete` | Registration |
| `logout` | Sign out |
| `screen_view` | Named routes only |
| `tab_selected` | Bottom nav tab |
| `feature_used` | Tab, chat, community post, … |
| `ai_question_sent` | User sends chat message |
| `testimonial_submitted` | Settings feedback sheet |

---

## Privacy & Play Store

- Analytics user id = internal `users.id` UUID (set via `setUserId`).
- No email, chat text, symptoms, or names in GA4 events.
- Add Firebase to your **Privacy Policy** and Play **Data safety** form.
- Mark collection of app activity / diagnostics as applicable.

---

## Verify it works

1. Set `DefaultFirebaseOptions.enabled = true` and add `google-services.json`.
2. Run release build or set `FIREBASE_ANALYTICS_ENABLED=true` in debug.
3. Firebase Console → **Analytics → DebugView** (enable debug mode on device).
4. Log in, switch tabs, send a chat message, submit feedback.
5. Events should appear in DebugView within seconds; standard reports lag 24–48h.

Android debug mode:

```bash
adb shell setprop debug.firebase.analytics.app com.momlaunchpad.app
```
