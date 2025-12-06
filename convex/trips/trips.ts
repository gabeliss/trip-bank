import { mutation, query } from "../_generated/server";
import { v } from "convex/values";
import { requireAuth } from "../auth";
import { canUserView, canUserEdit, isOwner } from "./permissions";

// ============= TRIP MUTATIONS =============

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
      userId, // Keep for backward compatibility
      ownerId: userId, // New owner field
      tripId: args.tripId,
      title: args.title,
      startDate: args.startDate,
      endDate: args.endDate,
      coverImageName: args.coverImageName,
      coverImageStorageId: args.coverImageStorageId,
      createdAt: now,
      updatedAt: now,
    });

    // Create owner permission
    await ctx.db.insert("tripPermissions", {
      tripId: args.tripId,
      userId: userId,
      role: "owner",
      grantedVia: "share_link", // Owner doesn't come from share, but need a value
      invitedBy: userId, // Self-invited
      acceptedAt: now,
      createdAt: now,
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
    previewImageStorageId: v.optional(v.id("_storage")),
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

    // Check permission (owner or collaborator can edit)
    if (!(await canUserEdit(ctx, args.tripId, userId))) {
      throw new Error("You don't have permission to edit this trip");
    }

    const updates: any = {
      updatedAt: Date.now(),
    };

    if (args.title !== undefined) updates.title = args.title;
    if (args.startDate !== undefined) updates.startDate = args.startDate;
    if (args.endDate !== undefined) updates.endDate = args.endDate;
    if (args.coverImageName !== undefined) updates.coverImageName = args.coverImageName;
    if (args.coverImageStorageId !== undefined) updates.coverImageStorageId = args.coverImageStorageId;
    if (args.previewImageStorageId !== undefined) updates.previewImageStorageId = args.previewImageStorageId;

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

    // Only owner can delete trip
    if (!(await isOwner(ctx, args.tripId, userId))) {
      throw new Error("Only the trip owner can delete the trip");
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
      // Delete thumbnail from storage if it exists
      if (item.thumbnailStorageId) {
        await ctx.storage.delete(item.thumbnailStorageId);
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

    // Delete all trip permissions
    const permissions = await ctx.db
      .query("tripPermissions")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    for (const permission of permissions) {
      await ctx.db.delete(permission._id);
    }

    // Delete preview image if it exists
    if (trip.previewImageStorageId) {
      await ctx.storage.delete(trip.previewImageStorageId);
    }

    // Delete the trip itself
    await ctx.db.delete(trip._id);
    return { success: true };
  },
});

// ============= TRIP QUERIES =============

// Get all trips for the authenticated user
export const getAllTrips = query({
  args: {},
  handler: async (ctx) => {
    const userId = await requireAuth(ctx);

    const trips = await ctx.db
      .query("trips")
      .withIndex("by_userId_createdAt", (q) => q.eq("userId", userId))
      .collect();

    // Sort by startDate descending (most recent trips first)
    trips.sort((a, b) => b.startDate - a.startDate);

    // Add userRole for each trip by looking up permissions
    const tripsWithRole = await Promise.all(
      trips.map(async (trip) => {
        // Look up user's permission for this trip
        const permission = await ctx.db
          .query("tripPermissions")
          .withIndex("by_tripId_userId", (q) =>
            q.eq("tripId", trip.tripId).eq("userId", userId)
          )
          .first();

        return {
          ...trip,
          userRole: permission?.role || null,
        };
      })
    );

    return tripsWithRole;
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

    if (!trip) {
      return null;
    }

    // Check if user has permission to view this trip
    if (!(await canUserView(ctx, args.tripId, userId))) {
      return null;
    }

    // Look up user's permission for this trip
    const permission = await ctx.db
      .query("tripPermissions")
      .withIndex("by_tripId_userId", (q) =>
        q.eq("tripId", args.tripId).eq("userId", userId)
      )
      .first();

    const mediaItems = await ctx.db
      .query("mediaItems")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    const moments = await ctx.db
      .query("moments")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    return {
      trip: {
        ...trip,
        userRole: permission?.role || null,
      },
      mediaItems,
      moments,
    };
  },
});
