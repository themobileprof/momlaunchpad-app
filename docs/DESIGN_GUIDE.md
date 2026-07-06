# MomLaunchpad Design Guide

This guide ensures visual consistency across the MomLaunchpad frontend, derived from the logo and UX principles.

## Design Philosophy

**Core Principle:** Calm conversation, not an app.

The interface should feel like a gentle assistant - nurturing, modern, and friendly. Users are pregnant mothers seeking support, not power users navigating complex software.

### App launcher icon

Home-screen / store icons are generated from `assets/images/logo.png` (same asset as in-app branding). After updating the logo, regenerate platform icons:

```bash
dart run flutter_launcher_icons
```

Config lives in `pubspec.yaml` under `flutter_launcher_icons` (mint canvas `#F0FDFA`, adaptive Android foreground).

---

## Color Palette

Extracted from the logo:

### Primary Colors

```dart
// lib/theme/colors.dart
const Color primaryPink = Color(0xFFE91E63);      // Soft pink/coral - Primary CTA
const Color primaryPurple = Color(0xFF5E548E);    // Deep purple/indigo - Secondary actions
const Color backgroundLight = Color(0xFFFAF9F6);  // Off-white/very light pink
const Color textDark = Color(0xFF424242);         // Dark gray (NOT black #000000)
const Color textLight = Color(0xFF757575);        // Medium gray for secondary text
const Color white = Color(0xFFFFFFFF);            // Pure white for cards/contrast
```

### Usage Rules

- **Primary CTA buttons:** `primaryPink`
- **Secondary actions:** `primaryPurple` 
- **App background:** `backgroundLight`
- **Primary text:** `textDark` (never pure black)
- **Secondary text/hints:** `textLight`
- **Cards/elevated surfaces:** `white`

❌ **Forbidden:**
- Pure black (`#000000`) for text
- Harsh reds for errors (use soft coral)
- Dense, saturated colors

---

## Typography

### Font Setup

Use **2-3 font sizes maximum** to maintain visual hierarchy:

```dart
// lib/theme/typography.dart
const TextStyle headingLarge = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  color: textDark,
  height: 1.3,
);

const TextStyle headingMedium = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  color: textDark,
  height: 1.4,
);

const TextStyle bodyText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.normal,
  color: textDark,
  height: 1.6,
);

const TextStyle caption = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.normal,
  color: textLight,
  height: 1.5,
);
```

### Font Pairing

**Primary:** System default (SF Pro on iOS, Roboto on Android)

**Alternative:** If custom font needed, use:
- Inter
- DM Sans
- Plus Jakarta Sans

---

## Spacing System

Use consistent spacing multiples of **8**:

```dart
// lib/theme/spacing.dart
const double spaceXS = 4.0;
const double spaceSM = 8.0;
const double spaceMD = 16.0;
const double spaceLG = 24.0;
const double spaceXL = 32.0;
const double spaceXXL = 48.0;
```

### Layout Padding

- **Screen edges:** `spaceLG` (24px)
- **Card padding:** `spaceMD` (16px)
- **Between sections:** `spaceXL` (32px)
- **Between related items:** `spaceMD` (16px)
- **Tight spacing:** `spaceSM` (8px)

---

## Component Patterns

### Border Radius

**All components use rounded corners** (no sharp edges):

```dart
// lib/theme/shapes.dart
const double radiusSmall = 12.0;
const double radiusMedium = 16.0;
const double radiusLarge = 24.0;
const double radiusCircle = 999.0;  // For circular elements
```

**Usage:**
- **Buttons:** `radiusMedium` (16)
- **Cards:** `radiusLarge` (24)
- **Input fields:** `radiusMedium` (16)
- **Bottom sheets:** `radiusLarge` (24) top corners only
- **Avatar/profile:** `radiusCircle`

### Cards Over Lists

Prefer elevated cards with shadows over flat list items:

```dart
Container(
  margin: EdgeInsets.all(spaceMD),
  padding: EdgeInsets.all(spaceMD),
  decoration: BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: // content
)
```

### Spacing Over Lines

Prefer whitespace separation over dividers:

❌ **Avoid:**
```dart
ListTile(
  title: Text('Item'),
  trailing: Divider(),
)
```

✅ **Prefer:**
```dart
Padding(
  padding: EdgeInsets.symmetric(vertical: spaceMD),
  child: // content
)
```

### Icons Over Text

Use icons to reduce cognitive load:

✅ **Good:**
```dart
IconButton(
  icon: Icon(Icons.calendar_today),
  onPressed: // action
)
```

❌ **Avoid:**
```dart
TextButton(
  child: Text('View Calendar'),
  onPressed: // action
)
```

---

## Screen-Specific Guidelines

### Chat Screen

**Goal:** Feel like a gentle conversation, not a messaging app.

**Design:**
- Message bubbles: large radius (`radiusLarge`)
- User messages: `primaryPink` background
- AI messages: `white` with subtle shadow
- Generous vertical spacing between messages (`spaceLG`)
- Hide timestamps (show only on long-press if needed)
- Soft typing indicator (animated dots, not jarring)

**Example:**
```dart
// User message
Container(
  padding: EdgeInsets.all(spaceMD),
  decoration: BoxDecoration(
    color: primaryPink,
    borderRadius: BorderRadius.circular(radiusLarge),
  ),
  child: Text(
    'I feel nauseous today',
    style: bodyText.copyWith(color: white),
  ),
)

// AI message
Container(
  padding: EdgeInsets.all(spaceMD),
  decoration: BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Text(
    'It\'s completely normal...',
    style: bodyText,
  ),
)
```

### Calendar Screen

**Goal:** Soft planner, not aggressive task manager.

**Design:**
- Cards for reminders (not list tiles)
- Soft colors for priority levels (no harsh red)
- Empty state shows encouraging illustration
- FAB (Floating Action Button) in `primaryPink`

**Priority Colors:**
```dart
const Color priorityUrgent = Color(0xFFFF6B9D);   // Soft coral
const Color priorityHigh = Color(0xFFE91E63);     // Primary pink
const Color priorityMedium = Color(0xFF9C88C8);   // Soft purple
const Color priorityLow = Color(0xFFB8B8D0);      // Very soft gray-purple
```

### Savings Screen (Optional)

**Goal:** Progress journey, not financial stress.

**Design:**
- Progress rings/arcs (circular shapes)
- Soft animations on milestone achievement
- Encouraging copy ("You're doing great!")
- Celebrate wins with confetti animation (subtle)

### Admin Dashboard

**Goal:** Function over beauty. Keep it boring.

**Design:**
- Neutral grays
- Standard Material Design tables
- No animations
- Clear labels, simple forms
- Desktop-optimized (not mobile-first)

**Colors:**
```dart
// Admin only - boring on purpose
const Color adminBackground = Color(0xFFF5F5F5);
const Color adminPrimary = Color(0xFF1976D2);     // Standard blue
const Color adminText = Color(0xFF212121);
```

---

## Material 3 Configuration

Use Flutter's Material 3 with custom color overrides:

```dart
// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPink,
      primary: primaryPink,
      secondary: primaryPurple,
      background: backgroundLight,
      surface: white,
      onPrimary: white,
      onSecondary: white,
      onBackground: textDark,
      onSurface: textDark,
    ),
    
    // Override shape theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    
    // Override button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPink,
        foregroundColor: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: spaceLG,
          vertical: spaceMD,
        ),
      ),
    ),
    
    // Override input theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.all(spaceMD),
    ),
    
    // Typography
    textTheme: TextTheme(
      displayLarge: headingLarge,
      displayMedium: headingMedium,
      bodyLarge: bodyText,
      bodyMedium: bodyText,
      bodySmall: caption,
    ),
  );
}
```

---

## VSCode Setup (Developer Experience)

### Recommended Theme

Choose one (they align with logo aesthetics):

1. **Rosé Pine** (best match - pink/purple tones)
2. **Catppuccin Mocha** (good alternative)
3. **Tokyo Night Storm** (more contrast if needed)

### Font Settings

```json
// .vscode/settings.json
{
  "editor.fontFamily": "JetBrains Mono, Fira Code, monospace",
  "editor.fontLigatures": true,
  "editor.fontSize": 14,
  "editor.lineHeight": 1.6,
  "editor.formatOnSave": true,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true
}
```

---

## Design Workflow

### Critical Rule: Design First, Code Second

❌ **Don't:**
- Design while coding
- "I'll just tweak this color..."
- Experiment with layouts in production code

✅ **Do:**
1. **Lock theme** - Define all colors, spacing, radii first
2. **Lock typography** - Set 2-3 font sizes max
3. **Create theme file** - `lib/theme/app_theme.dart`
4. **Code blindly** - Reference theme constants only, never hardcode values

### Theme Constants Only

❌ **Bad:**
```dart
Container(
  color: Color(0xFFE91E63),
  padding: EdgeInsets.all(16),
  // ...
)
```

✅ **Good:**
```dart
Container(
  color: primaryPink,
  padding: EdgeInsets.all(spaceMD),
  // ...
)
```

---

## Testing Design Consistency

### Visual Regression Testing

Use **Golden Tests** for UI components:

```dart
// test/widgets/message_bubble_test.dart
testWidgets('User message bubble matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      home: Scaffold(
        body: MessageBubble(
          text: 'Test message',
          isUser: true,
        ),
      ),
    ),
  );
  
  await expectLater(
    find.byType(MessageBubble),
    matchesGoldenFile('goldens/user_message_bubble.png'),
  );
});
```

### Design Checklist

Before committing UI code, verify:

- [ ] No hardcoded colors (use theme constants)
- [ ] No hardcoded spacing (use spacing constants)
- [ ] All corners rounded (no `BorderRadius.zero`)
- [ ] Text color is `textDark` or `textLight` (not black)
- [ ] Cards have shadows, not borders
- [ ] Icons used where appropriate
- [ ] Spacing > dividers

---

## Common Mistakes to Avoid

### ❌ Don't

1. **Pure black text:** Use `textDark` (`#424242`)
2. **Sharp corners:** Everything needs `borderRadius`
3. **Dense layouts:** Generous spacing is required
4. **Too many colors:** Stick to pink, purple, grays
5. **Divider lines everywhere:** Use whitespace
6. **Small touch targets:** Minimum 48x48 for buttons
7. **Harsh error red:** Use soft coral instead

### ✅ Do

1. **Embrace whitespace** - Less is more
2. **Use shadows** - Depth over borders
3. **Round everything** - 16-24px radius standard
4. **Consistent spacing** - Multiples of 8
5. **Icons first** - Reduce text where possible
6. **Test on real devices** - Not just simulator
7. **Follow Material 3** - Let it do heavy lifting

---

## Animation Guidelines

### When to Animate

- Screen transitions (slide/fade)
- Button presses (subtle scale)
- Loading states (gentle pulse)
- Success celebrations (soft confetti)

### When NOT to Animate

- Text appearance
- List scrolling
- Routine actions
- Admin dashboard (keep it boring)

### Animation Duration

```dart
const Duration animationQuick = Duration(milliseconds: 150);
const Duration animationMedium = Duration(milliseconds: 300);
const Duration animationSlow = Duration(milliseconds: 500);
```

Use `Curves.easeInOut` for most animations (not linear).

---

## Accessibility

### Color Contrast

All text must meet WCAG AA standards:

- **Normal text:** Minimum 4.5:1 contrast ratio
- **Large text (18pt+):** Minimum 3:1 contrast ratio

Test with:
```bash
# Add contrast checker to dev dependencies
flutter pub add --dev contrast_checker
```

### Touch Targets

Minimum **48x48** logical pixels for all interactive elements.

### Screen Reader Support

```dart
Semantics(
  label: 'Send message button',
  button: true,
  child: IconButton(
    icon: Icon(Icons.send),
    onPressed: _sendMessage,
  ),
)
```

---

## Resources

### Design Tools

- **Figma:** For mockups (optional, but helpful)
- **Coolors.co:** Color palette testing
- **Contrast Checker:** WebAIM contrast checker

### Flutter Packages

```yaml
# pubspec.yaml
dependencies:
  google_fonts: ^6.1.0  # If using custom fonts
  flutter_animate: ^4.3.0  # Subtle animations
  
dev_dependencies:
  golden_toolkit: ^0.15.0  # Golden tests
```

### Inspiration

Look at apps with similar vibes:
- Calm (meditation app)
- Flo (period tracker)
- Headspace (mental health)

**Do NOT copy:**
- Banking apps (too corporate)
- Social media (too busy)
- Gaming apps (too energetic)

---

## Next Steps

1. **Create theme file:** `lib/theme/app_theme.dart`
2. **Define colors:** `lib/theme/colors.dart`
3. **Define spacing:** `lib/theme/spacing.dart`
4. **Define typography:** `lib/theme/typography.dart`
5. **Build component library:** `packages/ui/lib/`
6. **Create golden tests:** Snapshot UI components
7. **Never hardcode values** - Always reference theme

---

**Remember:** Calm, nurturing, modern, friendly. The app should feel like a supportive companion, not a tool.
