# Google Sign-In Setup Guide

## Overview
Google Sign-In has been integrated into MomLaunchpad mobile app. Follow these steps to complete the configuration.

## Prerequisites
- Google Cloud Project created
- SHA-1 certificate fingerprint (already generated)

## SHA-1 Certificate
**Debug SHA-1:** `08:8F:5C:3B:49:D2:EA:94:E1:D7:95:35:6B:46:C6:F6:1C:75:47:82`

## Setup Steps

### 1. Google Cloud Console Configuration

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable **Google+ API** or **Google Identity Services API**

### 2. Create OAuth 2.0 Credentials

#### Create Android OAuth Client
1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth client ID**
3. Select **Android** as application type
4. Enter package name: `com.momlaunchpad.app`
5. Enter SHA-1 certificate fingerprint: `08:8F:5C:3B:49:D2:EA:94:E1:D7:95:35:6B:46:C6:F6:1C:75:47:82`
6. Click **Create**

#### Create Web OAuth Client (for backend)
1. Click **Create Credentials** → **OAuth client ID**
2. Select **Web application**
3. Add authorized redirect URIs if needed
4. Click **Create**
5. **Copy the Web Client ID** - you'll need this!

### 3. Update Android Configuration

Edit `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Replace YOUR_WEB_CLIENT_ID_HERE with actual Web Client ID -->
    <string name="default_web_client_id">YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com</string>
</resources>
```

### 4. Backend Configuration

The backend needs the same **Web Client ID** to verify ID tokens. Make sure your backend is configured with:

```go
// Backend should validate ID tokens using the Web Client ID
clientID := "YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com"
```

### 5. Test the Integration

1. Run the app: `flutter run -d emulator-5554`
2. Navigate to login screen
3. Tap **"Continue with Google"** button
4. Select Google account
5. App should authenticate and receive JWT from backend

## How It Works

1. **User taps Google Sign-In** → Google authentication flow starts
2. **User selects account** → Google returns ID token
3. **App sends ID token to backend** → `POST /api/auth/google/token`
4. **Backend verifies ID token** → Validates with Google
5. **Backend returns JWT** → App stores JWT for authenticated requests
6. **App uses JWT** → All subsequent API calls use this JWT

## Files Modified

- `pubspec.yaml` - Added `google_sign_in: ^6.2.2`
- `lib/services/api_service.dart` - Added `googleSignIn()` method
- `lib/providers/auth_provider.dart` - Added `signInWithGoogle()` method
- `lib/screens/login_screen.dart` - Added Google Sign-In button
- `android/app/src/main/res/values/strings.xml` - Created for Web Client ID

## Troubleshooting

### "Sign-in failed" Error
- Verify SHA-1 is correctly added to Google Cloud Console
- Check package name matches exactly: `com.momlaunchpad.app`
- Ensure Web Client ID is correctly set in `strings.xml`

### "Unable to connect to server" Error
- Verify backend is running on `http://10.0.2.2:8080` (for emulator)
- Check backend has implemented `/api/auth/google/token` endpoint
- Verify backend is using same Web Client ID for token verification

### Account Picker Not Showing
- The app calls `googleSignIn.signOut()` before sign-in to ensure picker shows
- Make sure Google Play Services is up to date on device/emulator

## Production Notes

For production release:
1. Generate release keystore
2. Get SHA-1 for release keystore: `keytool -list -v -keystore release.keystore`
3. Add release SHA-1 to Google Cloud Console
4. Update OAuth client configuration for production domain

## Security Notes

- ID tokens are validated on the backend before issuing JWT
- Never store Google credentials in the app
- JWT tokens are stored securely using `flutter_secure_storage`
- Backend should verify ID token audience matches Web Client ID
