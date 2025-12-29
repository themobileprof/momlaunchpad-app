# MomLaunchpad Mobile Development Guide

## Project Overview

MomLaunchpad is a pregnancy support mobile app with a **thin Flutter client** and **intelligent Go backend**. The frontend is intentionally "dumb" - it handles UX, language detection, and user actions, while ALL business logic, memory, and AI orchestration lives in the backend.

**Key Architecture Principle:** Frontend = I/O layer. Backend = brain.

## Project Structure

```
momlaunchpad-mobile/
├── lib/
│   ├── main.dart
│   ├── screens/         # Chat, Calendar, Savings, Settings
│   ├── providers/       # Riverpod state management
│   ├── services/        # WebSocket, HTTP, Auth
│   ├── models/          # Data models (mirrors backend DTOs)
│   ├── widgets/         # Reusable UI components
│   └── theme/           # Colors, typography, spacing
├── test/
└── assets/
```

**Platform:** Android-first, iOS later (same codebase)  
**State Management:** Riverpod (chosen solution - use consistently)  
**Audience:** Pregnant users seeking calm, conversational support

## Critical Workflows

### WebSocket Chat (Primary Feature)
- **Connect:** `ws://api.momlaunchpad.com/ws/chat?token={JWT}`
- **Protocol:** Send `{"content": "message"}`, receive streaming chunks
- **Message Types:** `message` (chunks), `done`, `calendar` (suggestion), `error`
- **Must handle:** Chunk concatenation, rate limits (10 msg/min), reconnection, PII warnings
- **No caching:** Never cache AI responses locally

**Example flow:**
```dart
_channel.sink.add(jsonEncode({'content': 'I feel nauseous'}));
// Server streams: {type: "message", content: "..."} chunks
// Then: {type: "calendar", message: "Set reminder?"} (optional)
// Finally: {type: "done"}
```

See [docs/WEBSOCKET_GUIDE.md](docs/WEBSOCKET_GUIDE.md) for complete integration patterns.

### Language Detection (Local Only)
- **Use:** `google_mlkit_language_id` or similar
- **Rule:** Language detection NEVER happens on backend
- **Unsupported languages:** Prompt user to switch to EN/FR/ES (English/French/Spanish)
- **Send with message:** Include detected language code in metadata

### Authentication Flow
1. Login via HTTP POST `/api/auth/login` → Get JWT
2. Store JWT in `flutter_secure_storage`
3. Use JWT for all WebSocket connections and HTTP requests
4. Logout clears all local state

### Calendar/Reminders
- **Backend suggests** reminders (via WebSocket `calendar` type message)
- **User must confirm** explicitly via UI
- **Then POST** to `/api/reminders` (HTTP, not WebSocket)
- **Never create silently** - all calendar actions require user intent

## Project-Specific Patterns

### 1. Small Talk Handling
Backend returns instant canned responses for greetings (`hello`, `thanks`, `bye`). Do NOT show "typing..." indicators for small talk.

```dart
bool isSmallTalk(String content) {
  final patterns = ['hello', 'hi', 'thanks', 'bye'];
  return patterns.any((p) => content.toLowerCase().contains(p));
}
```

### 2. Streaming Response Accumulation
AI responses arrive in chunks. Concatenate until `type: "done"`:

```dart
String _currentResponse = '';

void _handleMessage(dynamic data) {
  switch (message['type']) {
    case 'message':
      _currentResponse += message['content'];
      _updateUI(_currentResponse); // Update progressively
      break;
    case 'done':
      _finalizeMessage(_currentResponse);
      _currentResponse = ''; // Reset for next message
      break;
  }
}
```

### 3. Fillers ("Let me check...")
- Use **deterministic fillers** only (never AI-generated)
- Show while waiting for first chunk
- Purpose: Mask latency, not add intelligence
- Never send fillers to backend

### 4. Rate Limiting (Client-Side)
Track message count locally to prevent 429 errors:

```dart
// 10 messages per minute limit
DateTime? _lastMessageTime;
int _messageCount = 0;

bool canSendMessage() {
  final now = DateTime.now();
  if (_lastMessageTime == null || 
      now.difference(_lastMessageTime!) > Duration(minutes: 1)) {
    _messageCount = 0;
  }
  return _messageCount < 10;
}
```

### 5. Reconnection Strategy
- Automatic reconnection after 3-5 seconds
- Exponential backoff on repeated failures
- Show connection status in UI (cloud icon)
- Detect network changes with `connectivity_plus`

## Backend Integration Points

### HTTP Endpoints (RESTful)
- `/api/auth/register`, `/api/auth/login`, `/api/auth/me`
- `/api/reminders` (GET, POST, PUT, DELETE)

### WebSocket (Chat Only)
- `/ws/chat?token={JWT}` - Stateless connection, session-aware backend

### Error Handling
- `429 Rate Limit`: Disable send button, show cooldown
- `401 Invalid Token`: Clear storage, redirect to login
- `type: "error"` in WS: Show toast, don't retry automatically

## Security Rules

1. **JWT storage:** `flutter_secure_storage` only
2. **Logout:** Clear all state (messages, reminders, user data)
3. **No sensitive caching:** Don't persist AI responses locally
4. **PII redaction:** If user inputs email/phone, backend handles redaction
5. **Offline behavior:** Show "Internet required" message, block sending

## Testing Approach

- **Unit tests:** Models, state management, parsing logic
- **Widget tests:** Message bubbles, input validation, error states
- **Integration tests:** WebSocket connection, HTTP auth flow
- **Mock WebSocket:** Use `mockito` or manual `StreamController`

## What NOT to Do

❌ **Don't implement AI logic** (intent classification, prompt building, memory) in Flutter  
❌ **Don't cache medical responses** locally  
❌ **Don't create reminders silently** without user confirmation  
❌ **Don't send fillers to backend**  
❌ **Don't guess language** - use ML Kit detection locally  
❌ **Don't retry failed AI messages automatically** (rate limits)  

## Key Files to Reference

- [FRONTEND_SPEC.md](FRONTEND_SPEC.md) - Complete frontend architecture
- [docs/WEBSOCKET_GUIDE.md](docs/WEBSOCKET_GUIDE.md) - Full WS integration with examples
- [docs/DESIGN_GUIDE.md](docs/DESIGN_GUIDE.md) - Visual design system and UI patterns
- [docs/API.md](docs/API.md) - Backend API reference
- [docs/BACKEND_SPEC.md](docs/BACKEND_SPEC.md) - Backend architecture (for context)

## Development Commands

```bash
# Run mobile app
cd appon Android device/emulator
flutter run

# Run on specific device
flutter run -d <device-id>

# Generate models from JSON
flutter pub run build_runner build

# Run tests
flutter test

# Build APK
flutter build apk

# Build App Bundle (for Play Store)
flutter build appbundle

## Production Considerations

- **Target devices:** Low-to-mid spec Android/iOS
- **Optimize:** Keep bundle size small, lazy-load screens
- **State management:** Riverpod (use `ConsumerWidget`, `StateNotifier`, `FutureProvider`, etc.)
- **Localization:** Use `flutter_localizations`, support EN/FR/ES at launch
- **Permissions:** Microphone (audio chat), network access only
- **Design system:** Follow [docs/DESIGN_GUIDE.md](docs/DESIGN_GUIDE.md) - soft pink/purple palette, rounded corners (16-24px), spacing over lines
- **Visual consistency:** Use theme constants only, never hardcode colors/spacing

---

**Philosophy:** The frontend is a presentation layer. All intelligence lives in the backend. When in doubt, ask the backend.