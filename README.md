# TripBank

A beautiful iOS app for creating and sharing trip memories with AI-powered organization.

## Overview

TripBank allows you to create stunning visual stories from your trips. Instead of sending scattered photos and long text messages, you can upload photos/videos, add context, and let AI organize everything into a beautiful, shareable experience.

## Features

- **Create Trips**: Organize your adventures by trip with dates and details
- **Upload Media**: Add photos and videos from your camera roll
- **Add Context**: Tag media with dates and notes
- **Group Photos**: Combine related photos (e.g., photos from a hike) with shared notes
- **AI Organization**: Claude AI analyzes your photos and creates a compelling visual story
- **Beautiful Layouts**: AI chooses the best layout styles (grid, carousel, featured, collage) for each section

## Setup Instructions

### 1. Create Xcode Project

Since this is a source-only distribution, you'll need to create an Xcode project:

1. Open Xcode
2. File → New → Project
3. Choose "iOS" → "App"
4. Fill in:
   - Product Name: `TripBank`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - Save location: Choose the `trip-bank` folder

5. **Important**: When saving, make sure the project is saved in `/Users/gabeliss/Desktop/trip-bank/` and check "Create Git repository" if you want version control

### 2. Add Files to Project

After creating the project, you need to add all the Swift files:

1. In Xcode's Project Navigator, right-click on the `TripBank` folder
2. Select "Add Files to TripBank..."
3. Navigate to the `TripBank` folder and select all `.swift` files
4. Make sure "Copy items if needed" is **unchecked** (files are already in the right place)
5. Click "Add"

The file structure should look like:
```
TripBank/
├── TripBankApp.swift
├── Config.swift
├── Info.plist
├── Models/
│   ├── Trip.swift
│   ├── MediaItem.swift
│   ├── MediaGroup.swift
│   ├── AILayout.swift
│   └── TripStore.swift
├── Views/
│   ├── ContentView.swift
│   ├── TripCardView.swift
│   ├── TripDetailView.swift
│   ├── NewTripView.swift
│   └── MediaPickerView.swift
└── Services/
    └── ClaudeService.swift
```

### 3. Configure Claude API

1. Get your API key from [Anthropic Console](https://console.anthropic.com/)
2. Open `TripBank/Config.swift`
3. Replace `YOUR_CLAUDE_API_KEY_HERE` with your actual API key:
   ```swift
   static let claudeAPIKey = "sk-ant-..."
   ```

**Important**: Never commit your API key to version control!

### 4. Configure Info.plist

Make sure `Info.plist` is properly configured in your Xcode project:

1. Select the project in Project Navigator
2. Select the `TripBank` target
3. Go to the "Info" tab
4. Verify these privacy permissions exist:
   - `Privacy - Photo Library Usage Description`
   - `Privacy - Photo Library Additions Usage Description`

If they don't exist, the `Info.plist` file in the TripBank folder has them already.

### 5. Build and Run

1. Select an iOS Simulator or your iPhone
2. Press Cmd+R to build and run
3. The app should launch showing the trips list

## Usage

### Creating a Trip

1. Tap the "+" button in the top right
2. Enter trip name and dates
3. Tap "Create"

### Adding Media

1. Open a trip from the list
2. Tap "Add Media"
3. Select photos/videos from your library
4. Tap "Add to Trip"

### AI Organization

1. After adding media, tap "Organize with AI"
2. Claude will analyze your photos and create sections
3. The AI will:
   - Write a narrative summary
   - Group photos into themed sections
   - Choose optimal layouts for each section
   - Create a cohesive visual story

### Adding Context

For each photo, you can add:
- Date/time of capture
- Notes describing the moment
- Group multiple photos together with shared notes

## Architecture

### Models
- **Trip**: Main trip entity with title, dates, media, and AI layout
- **MediaItem**: Individual photo/video with optional date and notes
- **MediaGroup**: Collection of related media items
- **AILayout**: AI-generated organization with sections and narrative

### Views
- **ContentView**: Main trips list
- **TripDetailView**: Single trip with AI-organized content
- **MediaPickerView**: Photo/video selection interface
- **TripCardView**: Trip preview card

### Services
- **ClaudeService**: Handles API communication with Claude AI
  - Sends images and context to Claude
  - Receives organized layout suggestions
  - Parses AI responses into structured layouts

## Technical Details

- **Platform**: iOS 17+
- **Framework**: SwiftUI
- **AI Model**: Claude 3.5 Sonnet (with vision)
- **Backend**: Convex (https://convex.dev)
- **Storage**: Cloud-based persistent storage via Convex
- **Deployment**: https://flippant-mongoose-94.convex.cloud

## Backend Setup

The app uses Convex for backend persistence. To deploy or update the backend:

```bash
cd convex
npm install
npx convex deploy
```

For more details, see [CONVEX_INTEGRATION.md](./CONVEX_INTEGRATION.md).

## Future Enhancements

- [x] ~~Persistent storage with SwiftData~~ **Completed with Convex!**
- [ ] User authentication and multi-device sync
- [ ] Cloud photo/video storage
- [ ] Share trips with family/friends
- [ ] Export as PDF or webpage
- [ ] Image generation for cover photos
- [ ] Video playback and trimming
- [ ] Location tagging with maps
- [ ] Collaborative trips
- [ ] Print photobooks

## License

Personal project - feel free to use and modify as you wish.
