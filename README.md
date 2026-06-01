# MomLaunchpad

**Your pocket companion for every chapter of motherhood — not just the highlight reel.**

Trying to conceive. Pregnant. Postpartum. Healing after loss. Each stage asks different questions, and you shouldn't have to hunt for answers across ten apps and a dozen group chats.

MomLaunchpad is a calm, private space where support meets your real life: a conversation when you need one, a community when you want company, and gentle tools that keep the practical stuff from slipping through the cracks.

---

## Why moms reach for it

**Talk it through, not type it into a search bar.**  
Chat with an AI companion that knows your journey stage, remembers what you've shared, and responds like a thoughtful friend — not a medical alarm bell. Streaming replies feel natural; you can vent, ask, or just check in.

**You're not doing this alone.**  
The community feed surfaces local posts and events near you — playdates, meetups, questions from moms who actually get it. Mark interest in an event and it lands on your calendar. Your profile photo and location help you show up as yourself (or stay anonymous when you prefer).

**One place for the stuff you keep forgetting.**  
Reminders and appointments live on your calendar. Log vitals and doctor visits. Track symptoms over time. The app learns from your chats to personalize nudges — without turning your phone into another chore list.

**Built for the whole journey.**  
Whether you're counting cycles, counting kicks, counting sleepless nights, or navigating grief, MomLaunchpad adapts its tone and focus to where you are — TTC, pregnancy, postpartum, or after loss.

---

## What's inside

| | |
|---|---|
| **Chat** | Real-time AI support over WebSocket, with calendar suggestions from conversation |
| **Community** | Local feed, events, interests, and onboarding tuned to your area |
| **Calendar** | Reminders linked to community events and daily life |
| **Health** | Symptom tracking, vitals logging, doctor visit records |
| **Profile** | Journey stage, preferences, and community location — all in your control |

Designed to feel **warm, fast, and non-judgmental**. No ads. No product pushing. Not a replacement for your care team — a steady hand on the days between appointments.

---

## For developers

This repo is the **Flutter mobile app** (Android-first, iOS-ready). It talks to the MomLaunchpad API via REST and WebSockets; business logic and AI live on the backend.

### Requirements

- Flutter 3.10+ (stable)
- Android SDK / Xcode for device builds
- A running [MomLaunchpad backend](https://github.com/themobileprof/momlaunchpad-be) (or production API)

### Quick start

```bash
git clone <this-repo>
cd momlaunchpad-fe

cp .env.example .env
# Edit .env — see comments for emulator vs physical device URLs

flutter pub get
flutter run
```

**Local API URLs**

| Target | `API_BASE_URL` | `WS_BASE_URL` |
|--------|----------------|---------------|
| Android emulator | `http://10.0.2.2:8080` | `ws://10.0.2.2:8080` |
| Physical device | `http://<your-lan-ip>:8080` | `ws://<your-lan-ip>:8080` |
| Production | `https://api.momlaunchpad.com` | `wss://api.momlaunchpad.com` |

Google Sign-In requires `GOOGLE_WEB_CLIENT_ID` in `.env` and matching Android/iOS config — see [docs/GOOGLE_SIGNIN_SETUP.md](docs/GOOGLE_SIGNIN_SETUP.md).

### Verify your setup

```bash
flutter analyze
flutter test
bash tool/refactor_check.sh   # analyze + largest files + dynamic usage audit
```

CI runs analyze and tests on push/PR; release APK builds use the GitHub `ENV_FILE` secret for production `.env` values.

### Stack

- **Flutter** + **Riverpod** for state
- **http** + **WebSockets** for API and chat streaming
- **flutter_secure_storage** for sessions
- **Google Sign-In**, **image_picker**, **intl**, and ML Kit for on-device language hints

### Project layout

```
lib/
  screens/     # Home, chat, community, calendar, profile, …
  widgets/     # Reusable UI (cards, chat bubbles, community, …)
  providers/   # Riverpod notifiers
  services/    # API, WebSocket, storage
  models/      # Typed DTOs
  theme/       # Colors, typography, spacing
docs/          # API, WebSocket, design, and setup guides
```

---

## Documentation

| Doc | Purpose |
|-----|---------|
| [FRONTEND_SPEC.md](FRONTEND_SPEC.md) | Product scope and UX principles |
| [IMPLEMENTED_FEATURES.md](IMPLEMENTED_FEATURES.md) | Feature checklist vs backend |
| [docs/API.md](docs/API.md) | REST endpoints |
| [docs/WEBSOCKET_GUIDE.md](docs/WEBSOCKET_GUIDE.md) | Chat protocol |
| [docs/DESIGN_GUIDE.md](docs/DESIGN_GUIDE.md) | Visual language |
| [docs/GOOGLE_SIGNIN_SETUP.md](docs/GOOGLE_SIGNIN_SETUP.md) | OAuth configuration |

---

## A note on care

MomLaunchpad offers **support and organization**, not diagnosis or emergency care. If something feels urgent, contact your provider or local emergency services.

---

*Built with care for moms who deserve software that meets them where they are.*
