# Clerk Authentication Setup for TripBank

This guide will walk you through setting up Clerk authentication for your TripBank iOS app with Convex backend.

## Overview

- **Authentication Provider**: Clerk
- **Backend**: Convex
- **Supported Methods**: Sign in with Apple, Google Sign-In
- **iOS SDK**: Clerk iOS SDK via Swift Package Manager

## Step 1: Create Clerk Account and Application

1. Go to [https://clerk.com](https://clerk.com) and sign up for a free account

2. Create a new application:
   - Click "Add application"
   - Name it "TripBank"
   - Select "iOS" as the platform
   - Enable **Sign in with Apple** and **Google**

3. After creation, you'll see your **Publishable Key** - save this for later
   - Example: `pk_test_xxxxx...`

## Step 2: Install Clerk iOS SDK

1. Open your Xcode project at `/Users/gabeliss/Desktop/trip-bank/trip-bank.xcodeproj`

2. Add the Clerk iOS SDK via Swift Package Manager:
   - Go to **File → Add Package Dependencies...**
   - Enter the URL: `https://github.com/clerk/clerk-ios`
   - Click **Add Package**
   - Select **ClerkSDK** when prompted

3. In `TripBankApp.swift`, initialize Clerk in the app's `init`:

```swift
import SwiftUI
import ClerkSDK

@main
struct TripBankApp: App {
    @StateObject private var tripStore = TripStore()
    @StateObject private var authService = ClerkAuthService.shared

    init() {
        // Configure Clerk with your publishable key
        Clerk.configure(publishableKey: "YOUR_CLERK_PUBLISHABLE_KEY")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(tripStore)
                } else {
                    LoginView()
                }
            }
            .environmentObject(authService)
        }
    }
}
```

**Replace `YOUR_CLERK_PUBLISHABLE_KEY` with your actual publishable key from Step 1.**

## Step 3: Configure Sign in with Apple in Clerk

1. In the Clerk Dashboard, go to **Configure → Authentication → Social connections**

2. Click on **Apple**

3. You already have your Apple setup from before:
   - **App ID**: `com.gabeliss.trip-bank`
   - **Service ID**: `com.gabeliss.trip-bank.auth`
   - **Key ID**: `GXFG3VFB7Q`
   - **Team ID**: `YHKHX97TXN`
   - **Private Key**: The contents of `TripBankAuthKey.p8`

4. Enter these details in Clerk and save

## Step 4: Configure Google Sign-In in Clerk

1. In the Clerk Dashboard, go to **Configure → Authentication → Social connections**

2. Click on **Google**

3. Follow Clerk's instructions to create a Google OAuth client:
   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Create a new project or select existing
   - Enable Google+ API
   - Create OAuth 2.0 credentials
   - Add Clerk's redirect URL (provided in Clerk dashboard)
   - Copy Client ID and Client Secret to Clerk

## Step 5: Configure Convex with Clerk

1. In Clerk Dashboard, go to **Configure → Deployments**

2. Copy your **Clerk Frontend API URL** (looks like: `https://your-domain.clerk.accounts.dev`)

3. Update `/Users/gabeliss/Desktop/trip-bank/convex.json`:

```json
{
  "authInfo": [
    {
      "domain": "https://your-domain.clerk.accounts.dev",
      "applicationID": "convex"
    }
  ]
}
```

**Replace `https://your-domain.clerk.accounts.dev` with your actual Clerk Frontend API URL.**

## Step 6: Deploy Convex Functions

1. Open Terminal and navigate to your project:

```bash
cd /Users/gabeliss/Desktop/trip-bank
```

2. Deploy to your dev deployment:

```bash
npx convex deploy --preview-create flippant-mongoose-94
```

Or update your existing deployment:

```bash
npx convex dev --once
```

3. Verify functions deployed successfully:
   - Check the Convex dashboard at https://dashboard.convex.dev/d/flippant-mongoose-94/functions
   - You should see: `auth:requireAuth`, `trips:createTrip`, `trips:getAllTrips`, etc.

## Step 7: Test Authentication

1. Build and run your iOS app in Xcode

2. You should see the login screen with:
   - Sign in with Apple button
   - Continue with Google button

3. Try signing in with Apple:
   - Click "Sign in with Apple"
   - Complete Apple authentication
   - App should authenticate and show main screen

4. Check Convex logs:
   - Go to your Convex dashboard
   - Check Logs tab
   - You should see authenticated requests with user ID

## Troubleshooting

### "Failed to get token" error
- Make sure Clerk is properly initialized in `TripBankApp.swift`
- Check that your publishable key is correct

### "Unauthorized" errors from Convex
- Verify `convex.json` has the correct Clerk domain
- Redeploy Convex functions: `npx convex dev --once`
- Check that Clerk session is active

### Apple Sign-In not working
- Verify your Apple configuration in Clerk matches your Apple Developer Portal
- Make sure redirect URLs are properly configured

### Google Sign-In not working
- Verify Google OAuth credentials in Clerk
- Check that redirect URLs match

## Environment Variables to Remove

You can now remove these from your Convex dashboard (they were for the old auth system):
- `AUTH_SECRET`
- `AUTH_SECRET_1`
- `AUTH_SECRET_2`
- `AUTH_APPLE_CLIENT_ID`
- `AUTH_APPLE_CLIENT_SECRET`
- `AUTH_GOOGLE_CLIENT_ID`
- `AUTH_GOOGLE_CLIENT_SECRET`

## Next Steps

Once authentication is working:

1. **Test data persistence**: Create a trip and verify it saves to Convex
2. **Test file uploads**: Try uploading photos (you'll need to implement the upload UI)
3. **Deploy to production**: Update `convex.json` for your prod deployment (silent-hare-226)

## Files Updated

The following files have been updated for Clerk integration:

- ✅ `/convex/schema.ts` - Updated for Clerk user table
- ✅ `/convex/auth.ts` - New helper functions for Clerk auth
- ✅ `/convex/trips.ts` - Updated to use Clerk authentication
- ✅ `/convex/files.ts` - Updated to use Clerk authentication
- ✅ `/convex.json` - New config file for Clerk
- ✅ `/trip-bank/Services/ClerkAuthService.swift` - New Clerk auth service
- ✅ `/trip-bank/Services/ConvexClient.swift` - Updated to use Clerk tokens
- ✅ `/trip-bank/TripBankApp.swift` - Updated to use ClerkAuthService
- ✅ `/trip-bank/Views/LoginView.swift` - Updated to use ClerkAuthService

## Support

- **Clerk Docs**: https://clerk.com/docs
- **Clerk iOS SDK**: https://clerk.com/docs/references/ios/overview
- **Convex + Clerk**: https://docs.convex.dev/auth/clerk
