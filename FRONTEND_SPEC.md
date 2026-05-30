📱 Mobile App Specification

Product: MomLaunchpad Mobile
Platform: Flutter (Android-first)
Audience: Pregnant users
Repo: momlaunchpad-mobile

1. Purpose & Scope

The mobile app is the core product.
It provides:

Conversational pregnancy support (text chat; live calls planned for Premium)

Background logging via chat

Calendar reminders and appointments

Lightweight savings tracker (MVP-level)

The app must feel:

Calm

Fast

Conversational

Non-judgmental

Safe

2. Non-Goals (Explicit)

No medical diagnosis

No ads or product pushing

No admin functions

No SEO concerns

No business logic duplication

3. Supported Platforms

Android (primary)

iOS (later, same codebase)

4. Architecture Overview
Pattern

Presentation: Flutter UI

State: Riverpod

Networking: WebSockets + REST

Logic: Minimal, backend-driven

Offline: Awareness only (no offline AI)

5. Core Features (MVP)
5.1 Conversational Chat (Primary Feature)
Capabilities

Text input → text output

Text chat via WebSocket → AI → streamed text response

WebSocket streaming for low latency

Natural pauses + fillers (“One moment…”)

Flow
User speaks/types
→ Local language detection
→ Text sent to backend via WebSocket
→ Streaming response received
→ UI updates incrementally
→ Optional live calls (Premium, coming soon)

UX Rules

No “submit” feeling — conversational

Bot uses short paragraphs

No medical alarmism

Small talk allowed, but not logged unless meaningful

5.2 Language Handling (Client-side)

Language auto-detected locally (e.g. MLKit)

Only supported languages allowed to proceed

User prompted to switch to supported language

Backend remains language-agnostic

5.3 Calendar (Secondary Feature)
Capabilities

View upcoming reminders

Suggested entries from chat (“Want to add this?”)

Manual add/edit/delete

Read-only doctor-added entries (future)

Calendar Types

Appointments

Medication reminders

Personal notes

5.4 Savings (MVP-lite)

Single savings goal

Target amount

Due date

Progress visualization

No payments handled in MVP

Treated as a motivational tracker, not fintech.

6. Screens
Required Screens

Onboarding

Chat (default landing)

Calendar

Savings

Settings

Offline / No-internet screen

7. Security

JWT stored securely (Keychain / Keystore)

No sensitive logic on-device

No medical data stored unencrypted

All AI calls via backend only

8. Performance Targets

Chat response start < 1.5s

Chat first response < 3s (streaming)

App cold start < 2s

Battery-safe background usage

9. Telemetry (Minimal)

App crashes

Latency metrics

Feature usage (anonymous)

No invasive tracking.

10. Release Strategy

Closed beta (20–50 users)

Play Store internal testing

Fast iteration cycles