import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireAuth } from "./auth";

// ============= MUTATIONS =============

// Create a new trip
export const createTrip = mutation({
  args: {
    tripId: v.string(),
    title: v.string(),
    startDate: v.number(),
    endDate: v.number(),
    coverImageName: v.optional(v.string()),
    coverImageStorageId: v.optional(v.id("_storage")),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const now = Date.now();

    const tripDocId = await ctx.db.insert("trips", {
      userId,
      tripId: args.tripId,
      title: args.title,
      startDate: args.startDate,
      endDate: args.endDate,
      coverImageName: args.coverImageName,
      coverImageStorageId: args.coverImageStorageId,
      createdAt: now,
      updatedAt: now,
    });

    return tripDocId;
  },
});

// Update an existing trip
export const updateTrip = mutation({
  args: {
    tripId: v.string(),
    title: v.optional(v.string()),
    startDate: v.optional(v.number()),
    endDate: v.optional(v.number()),
    coverImageName: v.optional(v.string()),
    coverImageStorageId: v.optional(v.id("_storage")),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const trip = await ctx.db
      .query("trips")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .first();

    if (!trip) {
      throw new Error(`Trip not found: ${args.tripId}`);
    }

    // Verify ownership
    if (trip.userId !== userId) {
      throw new Error("Unauthorized: You don't own this trip");
    }

    const updates: any = {
      updatedAt: Date.now(),
    };

    if (args.title !== undefined) updates.title = args.title;
    if (args.startDate !== undefined) updates.startDate = args.startDate;
    if (args.endDate !== undefined) updates.endDate = args.endDate;
    if (args.coverImageName !== undefined) updates.coverImageName = args.coverImageName;
    if (args.coverImageStorageId !== undefined) updates.coverImageStorageId = args.coverImageStorageId;

    await ctx.db.patch(trip._id, updates);
    return trip._id;
  },
});

// Delete a trip and all its media items and moments
export const deleteTrip = mutation({
  args: {
    tripId: v.string(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Find and delete the trip
    const trip = await ctx.db
      .query("trips")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .first();

    if (!trip) {
      throw new Error(`Trip not found: ${args.tripId}`);
    }

    // Verify ownership
    if (trip.userId !== userId) {
      throw new Error("Unauthorized: You don't own this trip");
    }

    // Delete all associated media items
    const mediaItems = await ctx.db
      .query("mediaItems")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    for (const item of mediaItems) {
      // Delete file from storage if it exists
      if (item.storageId) {
        await ctx.storage.delete(item.storageId);
      }
      await ctx.db.delete(item._id);
    }

    // Delete all associated moments
    const moments = await ctx.db
      .query("moments")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    for (const moment of moments) {
      await ctx.db.delete(moment._id);
    }

    // Delete cover image from storage if it exists
    if (trip.coverImageStorageId) {
      await ctx.storage.delete(trip.coverImageStorageId);
    }

    // Delete the trip itself
    await ctx.db.delete(trip._id);
    return { success: true };
  },
});

// Add a media item to a trip
export const addMediaItem = mutation({
  args: {
    mediaItemId: v.string(),
    tripId: v.string(),
    imageName: v.string(),
    imageURL: v.optional(v.string()),
    videoURL: v.optional(v.string()),
    storageId: v.optional(v.id("_storage")),
    type: v.union(v.literal("photo"), v.literal("video")),
    captureDate: v.optional(v.number()),
    note: v.optional(v.string()),
    timestamp: v.number(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const now = Date.now();

    const mediaItemDocId = await ctx.db.insert("mediaItems", {
      userId,
      mediaItemId: args.mediaItemId,
      tripId: args.tripId,
      imageName: args.imageName,
      imageURL: args.imageURL,
      videoURL: args.videoURL,
      storageId: args.storageId,
      type: args.type,
      captureDate: args.captureDate,
      note: args.note,
      timestamp: args.timestamp,
      createdAt: now,
      updatedAt: now,
    });

    return mediaItemDocId;
  },
});

// Add a moment to a trip
export const addMoment = mutation({
  args: {
    momentId: v.string(),
    tripId: v.string(),
    title: v.string(),
    note: v.optional(v.string()),
    mediaItemIDs: v.array(v.string()),
    timestamp: v.number(),
    date: v.optional(v.number()),
    placeName: v.optional(v.string()),
    eventName: v.optional(v.string()),
    voiceNoteURL: v.optional(v.string()),
    importance: v.union(
      v.literal("small"),
      v.literal("medium"),
      v.literal("large"),
      v.literal("hero")
    ),
    layoutPosition: v.optional(v.object({
      x: v.number(),
      y: v.number(),
    })),
    layoutSize: v.optional(
      v.union(
        v.literal("compact"),
        v.literal("regular"),
        v.literal("large"),
        v.literal("hero"),
        v.literal("wide"),
        v.literal("tall")
      )
    ),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const now = Date.now();

    const momentDocId = await ctx.db.insert("moments", {
      userId,
      momentId: args.momentId,
      tripId: args.tripId,
      title: args.title,
      note: args.note,
      mediaItemIDs: args.mediaItemIDs,
      timestamp: args.timestamp,
      date: args.date,
      placeName: args.placeName,
      eventName: args.eventName,
      voiceNoteURL: args.voiceNoteURL,
      importance: args.importance,
      layoutPosition: args.layoutPosition,
      layoutSize: args.layoutSize,
      createdAt: now,
      updatedAt: now,
    });

    return momentDocId;
  },
});

// ============= QUERIES =============

// Get all trips for the authenticated user
export const getAllTrips = query({
  args: {},
  handler: async (ctx) => {
    const userId = await requireAuth(ctx);

    const trips = await ctx.db
      .query("trips")
      .withIndex("by_userId_createdAt", (q) => q.eq("userId", userId))
      .order("desc")
      .collect();

    return trips;
  },
});

// Get a single trip with all its media items and moments
export const getTrip = query({
  args: {
    tripId: v.string(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const trip = await ctx.db
      .query("trips")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .first();

    if (!trip || trip.userId !== userId) {
      return null;
    }

    const mediaItems = await ctx.db
      .query("mediaItems")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    const moments = await ctx.db
      .query("moments")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    return {
      trip,
      mediaItems,
      moments,
    };
  },
});

// Get all media items for a trip
export const getMediaItems = query({
  args: {
    tripId: v.string(),
  },
  handler: async (ctx, args) => {
    const mediaItems = await ctx.db
      .query("mediaItems")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    return mediaItems;
  },
});

// Get all moments for a trip
export const getMoments = query({
  args: {
    tripId: v.string(),
  },
  handler: async (ctx, args) => {
    const moments = await ctx.db
      .query("moments")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    return moments;
  },
});
