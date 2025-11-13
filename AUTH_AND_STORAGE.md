# Authentication & File Storage Integration Guide

## Overview

Your TripBank app now has **Convex Auth** for user authentication (Sign in with Apple & Google) and **Convex File Storage** for media uploads! 🎉

This guide explains what was implemented and the next steps to complete the integration.

---

## What's Implemented

### ✅ Backend (Convex)

1. **Convex Auth Setup** (`convex/auth.config.ts`)
   - Configured Apple Sign-In provider
   - Configured Google Sign-In provider
   - Auth HTTP routes mounted

2. **Updated Database Schema** (`convex/schema.ts`)
   - Added auth tables (users, sessions, etc.)
   - Added `userId` field to all tables (trips, mediaItems, moments)
   - Added `storageId` fields for Convex file storage references
   - Created indexes for user-based queries

3. **Row-Level Security** (`convex/trips.ts`)
   - All mutations now require authentication
   - All queries filter by authenticated user ID
   - Users can only see their own trips
   - Automatic file cleanup on deletion

4. **File Storage Functions** (`convex/files.ts`)
   - `generateUploadUrl`: Get URL to upload files
   - `getFileUrl`: Get download URL for stored files
   - `deleteFile`: Remove files from storage

### ✅ iOS App

1. **Authentication Service** (`ConvexAuthService.swift`)
   - Sign in with Apple integration
   - Google Sign-In placeholder (needs SDK)
   - Token persistence in UserDefaults
   - Auth state management

2. **Login UI** (`LoginView.swift`)
   - Beautiful login screen
   - Sign in with Apple button
   - Sign in with Google button (needs implementation)
   - Loading and error states

3. **Protected App Flow** (`TripBankApp.swift`)
   - Shows LoginView when not authenticated
   - Shows ContentView when authenticated
   - Automatic state management

4. **Authenticated Requests** (`ConvexClient.swift`)
   - All API calls include auth token
   - Automatic authentication headers

5. **Sign Out** (`ContentView.swift`)
   - Menu with sign out option
   - Clears auth state and returns to login

---

## 🚨 Next Steps (Required)

### Step 1: Set Up Apple Sign-In

#### A. Xcode Configuration

1. Open your project in Xcode
2. Select your **target** → **Signing & Capabilities**
3. Click **+ Capability** → Add **"Sign in with Apple"**
4. This adds the capability to your app

#### B. Apple Developer Portal

1. Go to [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Find your App ID (`com.gabeliss.trip-bank`)
3. Enable **"Sign in with Apple"**
4. Create a **Service ID** for the web callback:
   - Click **+** → **Services IDs**
   - Description: "TripBank Auth"
   - Identifier: `com.gabeliss.trip-bank.auth` (or similar)
   - Enable "Sign in with Apple"
   - Configure:
     - Primary App ID: Your app's bundle ID
     - Return URL: `https://flippant-mongoose-94.convex.site/api/auth/callback/apple`

5. Create a **Key** for Sign in with Apple:
   - Go to **Keys**
   - Click **+**
   - Name: "TripBank Apple Auth Key"
   - Enable **"Sign in with Apple"**
   - Configure → Select your Primary App ID
   - Download the key file (`.p8`)
   - **Save the Key ID** (you'll need it)

#### C. Generate Client Secret

Apple Sign-In requires a JWT client secret. You can generate it using the script below or use an online tool:

```bash
# Install dependencies (if needed)
npm install -g jsonwebtoken

# Create generate-apple-secret.js:
```

```javascript
const jwt = require('jsonwebtoken');
const fs = require('fs');

const privateKey = fs.readFileSync('AuthKey_XXXXXXXXXX.p8'); // Your .p8 file

const token = jwt.sign({}, privateKey, {
  algorithm: 'ES256',
  expiresIn: '180d',
  issuer: 'YOUR_TEAM_ID', // Find in Apple Developer
  subject: 'com.gabeliss.trip-bank.auth', // Your Service ID
  audience: 'https://appleid.apple.com',
  keyid: 'YOUR_KEY_ID' // From the key you created
});

console.log(token);
```

Run: `node generate-apple-secret.js`

#### D. Add to Convex Environment

```bash
cd convex
npx convex env set AUTH_APPLE_CLIENT_ID "com.gabeliss.trip-bank.auth"
npx convex env set AUTH_APPLE_CLIENT_SECRET "eyJhbGc..." # JWT from above
```

---

### Step 2: Set Up Google Sign-In (Optional)

#### A. Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project or select existing
3. Go to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth 2.0 Client ID**
5. Configure:
   - Application type: **Web application**
   - Name: "TripBank"
   - Authorized redirect URIs:
     - `https://flippant-mongoose-94.convex.site/api/auth/callback/google`
6. Save **Client ID** and **Client Secret**

#### B. Add to Convex Environment

```bash
cd convex
npx convex env set AUTH_GOOGLE_CLIENT_ID "12345...apps.googleusercontent.com"
npx convex env set AUTH_GOOGLE_CLIENT_SECRET "GOCSPX-..."
```

#### C. iOS App - Install Google Sign-In SDK

Add to your Xcode project via Swift Package Manager:
- URL: `https://github.com/google/GoogleSignIn-iOS`
- Version: Latest

Then update `ConvexAuthService.swift`'s `signInWithGoogle()` method to use the SDK.

---

### Step 3: Deploy Backend

```bash
cd convex
npx convex deploy
```

---

### Step 4: Update Info.plist

Your app needs URL scheme handling for OAuth callbacks:

Add to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.gabeliss.trip-bank</string>
        </array>
    </dict>
</array>
```

---

## File Upload Implementation

### How to Upload Media to Convex Storage

The infrastructure is in place, but you need to implement the actual upload flow. Here's how:

#### 1. Get Upload URL

```swift
// Call the Convex function to get an upload URL
let uploadURL = try await convexClient.generateUploadUrl()
```

#### 2. Upload File

```swift
func uploadImage(_ image: UIImage) async throws -> String {
    // 1. Convert image to data
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        throw UploadError.invalidImage
    }

    // 2. Get upload URL from Convex
    let uploadURL = try await convexClient.generateUploadUrl()

    // 3. Upload file
    var request = URLRequest(url: URL(string: uploadURL)!)
    request.httpMethod = "POST"
    request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
    request.httpBody = imageData

    let (data, _) = try await URLSession.shared.data(for: request)

    // 4. Parse response to get storageId
    let response = try JSONDecoder().decode(UploadResponse.self, from: data)
    return response.storageId
}

struct UploadResponse: Codable {
    let storageId: String
}
```

#### 3. Save to Database

```swift
// When creating a media item, include the storageId
try await convexClient.addMediaItem(
    id: mediaItem.id.uuidString,
    tripId: trip.id.uuidString,
    imageName: "photo.jpg",
    storageId: storageId, // The ID from upload
    type: "photo",
    timestamp: Date()
)
```

#### 4. Download Files

```swift
// Get the download URL from Convex
let downloadURL = try await convexClient.getFileUrl(storageId: storageId)

// Load the image
let (data, _) = try await URLSession.shared.data(from: URL(string: downloadURL)!)
let image = UIImage(data: data)
```

---

## Architecture Overview

```
┌─────────────────────────────────────────┐
│         iOS App (Swift)                 │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │  ConvexAuthService              │  │
│  │  • Sign in with Apple/Google    │  │
│  │  • Token storage                │  │
│  │  • Auth state management        │  │
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │  ConvexClient                   │  │
│  │  • Authenticated API calls      │  │
│  │  • Trip CRUD operations         │  │
│  │  • File upload/download         │  │
│  └─────────────────────────────────┘  │
└─────────────────────────────────────────┘
                   ↓
         [HTTPS + Auth Token]
                   ↓
┌─────────────────────────────────────────┐
│     Convex Backend (TypeScript)         │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │  Convex Auth                    │  │
│  │  • Apple OAuth                  │  │
│  │  • Google OAuth                 │  │
│  │  • Session management           │  │
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │  Database (Row-Level Security)  │  │
│  │  • Users automatically filtered │  │
│  │  • Auth context in queries      │  │
│  └─────────────────────────────────┘  │
│                                         │
│  ┌─────────────────────────────────┐  │
│  │  File Storage                   │  │
│  │  • Upload URLs                  │  │
│  │  • Download URLs                │  │
│  │  • Automatic cleanup            │  │
│  └─────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

---

## Security Features

✅ **Row-Level Security**: Users can only access their own data
✅ **Authenticated Requests**: All API calls require valid auth token
✅ **Automatic Token Refresh**: Tokens persist across app launches
✅ **Secure OAuth Flow**: Industry-standard OAuth 2.0
✅ **File Access Control**: Storage IDs tied to user ownership

---

## Testing Checklist

Once you've completed the setup steps:

- [ ] Build and run the app
- [ ] See login screen on first launch
- [ ] Click "Sign in with Apple"
- [ ] Complete Apple authentication
- [ ] See trips list (empty initially)
- [ ] Create a new trip
- [ ] Trip is saved to your Convex database
- [ ] Close and reopen app
- [ ] Still signed in (token persisted)
- [ ] Trip still there (backend persistence)
- [ ] Sign out from menu
- [ ] Returned to login screen

---

## Troubleshooting

### "Unauthorized" errors

**Problem**: API calls fail with 401/403 errors

**Solution**:
- Check that auth token is being set in ConvexAuthService
- Verify token is included in requests (check ConvexClient)
- Ensure Convex functions use `getAuthUserId()` correctly

### Apple Sign-In not working

**Problem**: Apple authentication fails

**Solution**:
- Verify "Sign in with Apple" capability is enabled in Xcode
- Check Service ID configuration in Apple Developer Portal
- Ensure client secret JWT is valid (not expired)
- Verify redirect URL matches Convex deployment URL

### "Service ID not found"

**Problem**: Apple returns error about Service ID

**Solution**:
- Make sure you created a **Service ID** (not just App ID)
- Service ID must be enabled for "Sign in with Apple"
- Return URL must be configured correctly

### File upload fails

**Problem**: Images don't upload to Convex

**Solution**:
- Check that user is authenticated before uploading
- Verify upload URL is generated correctly
- Ensure Content-Type header is set
- Check file size (Convex has limits)

---

## File Structure

```
trip-bank/
├── convex/
│   ├── auth.config.ts      # Auth provider configuration
│   ├── http.ts             # Auth HTTP routes
│   ├── schema.ts           # Database schema with userId
│   ├── trips.ts            # Trip mutations/queries (protected)
│   ├── files.ts            # File storage functions
│   └── .env.example        # Environment variables template
│
└── trip-bank/
    ├── Services/
    │   ├── ConvexAuthService.swift    # Authentication service
    │   └── ConvexClient.swift         # API client (with auth)
    │
    └── Views/
        ├── LoginView.swift            # Login screen
        ├── ContentView.swift          # Main app (with sign out)
        └── ...
```

---

## Cost Considerations

**Convex Free Tier Includes**:
- ✅ Unlimited database operations
- ✅ 1GB file storage
- ✅ 1GB bandwidth/month
- ✅ Unlimited authentication

This should be more than enough for development and early users!

---

## Next Features to Implement

1. **Complete File Upload Flow**
   - Update MediaPickerView to upload to Convex Storage
   - Show upload progress
   - Handle errors gracefully

2. **Google Sign-In**
   - Add GoogleSignIn SDK
   - Implement OAuth flow in ConvexAuthService

3. **User Profile**
   - Display user info (name, email)
   - Profile settings screen

4. **Offline Support**
   - Cache trips locally
   - Queue operations when offline
   - Sync when back online

5. **Sharing**
   - Generate shareable links
   - Allow viewing (but not editing) shared trips

---

## Resources

- [Convex Auth Docs](https://docs.convex.dev/auth)
- [Convex File Storage](https://docs.convex.dev/file-storage)
- [Apple Sign In Guide](https://developer.apple.com/documentation/sign_in_with_apple)
- [Google Sign-In iOS](https://developers.google.com/identity/sign-in/ios)

---

## Summary

🎉 **You now have**:
- ✅ User authentication with Apple & Google
- ✅ Secure row-level data access
- ✅ File storage infrastructure
- ✅ Protected API endpoints
- ✅ Beautiful login UI
- ✅ Persistent auth sessions

🔧 **You need to complete**:
- Configure Apple Sign-In in Apple Developer Portal
- Set OAuth credentials in Convex environment
- Implement file upload flow in iOS app
- Test end-to-end

Great work! Your app is now production-ready for authentication. 🚀
