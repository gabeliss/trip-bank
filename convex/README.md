# TripBank Convex Backend

This directory contains the Convex backend for TripBank, providing persistent storage for trips, media items, and moments.

## Setup

1. Install dependencies:
   ```bash
   cd convex
   npm install
   ```

2. Deploy to Convex:
   ```bash
   npx convex deploy --url https://flippant-mongoose-94.convex.cloud
   ```

## Schema

The backend includes three main tables:

- **trips**: Main trip entities
- **mediaItems**: Photos and videos associated with trips
- **moments**: Grouped collections of media items

## Available Functions

### Mutations
- `createTrip`: Create a new trip
- `updateTrip`: Update trip details
- `deleteTrip`: Delete a trip and all associated data
- `addMediaItem`: Add a media item to a trip
- `addMoment`: Add a moment to a trip

### Queries
- `getAllTrips`: Fetch all trips
- `getTrip`: Fetch a specific trip with all media and moments
- `getMediaItems`: Fetch all media items for a trip
- `getMoments`: Fetch all moments for a trip

## Deployment

The backend is deployed at: https://flippant-mongoose-94.convex.cloud
