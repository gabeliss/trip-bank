import { mutation, query, QueryCtx, MutationCtx } from "./_generated/server";
import { v } from "convex/values";
import { requireAuth } from "./auth";

// ============= PERMISSION HELPERS =============

// Check if user can view a trip (has any access)
async function canUserView(
  ctx: QueryCtx | MutationCtx,
  tripId: string,
  userId: string
): Promise<boolean> {
  const trip = await ctx.db
    .query("trips")
    .withIndex("by_tripId", (q) => q.eq("tripId", tripId))
    .first();

  // Owner can always view
  if (trip?.ownerId === userId || trip?.userId === userId) return true;

  // Check if user has permission
  const permission = await ctx.db
    .query("tripPermissions")
    .withIndex("by_tripId_userId", (q) =>
      q.eq("tripId", tripId).eq("userId", userId)
    )
    .first();

  return permission !== null;
}

// Check if user can edit a trip (owner or collaborator)
async function canUserEdit(
  ctx: QueryCtx | MutationCtx,
  tripId: string,
  userId: string
): Promise<boolean> {
  const trip = await ctx.db
    .query("trips")
    .withIndex("by_tripId", (q) => q.eq("tripId", tripId))
    .first();

  // Owner can always edit
  if (trip?.ownerId === userId || trip?.userId === userId) return true;

  // Check if user is a collaborator
  const permission = await ctx.db
    .query("tripPermissions")
    .withIndex("by_tripId_userId", (q) =>
      q.eq("tripId", tripId).eq("userId", userId)
    )
    .first();

  return permission?.role === "collaborator";
}

// Check if user is the owner of a trip
async function isOwner(
  ctx: QueryCtx | MutationCtx,
  tripId: string,
  userId: string
): Promise<boolean> {
  const trip = await ctx.db
    .query("trips")
    .withIndex("by_tripId", (q) => q.eq("tripId", tripId))
    .first();

  return trip?.ownerId === userId || trip?.userId === userId;
}

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

// Add a media item to a trip
export const addMediaItem = mutation({
  args: {
    mediaItemId: v.string(),
    tripId: v.string(),
    storageId: v.optional(v.id("_storage")),
    thumbnailStorageId: v.optional(v.id("_storage")),
    imageURL: v.optional(v.string()),
    videoURL: v.optional(v.string()),
    type: v.union(v.literal("photo"), v.literal("video")),
    captureDate: v.optional(v.number()),
    note: v.optional(v.string()),
    timestamp: v.number(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Check permission to edit trip
    if (!(await canUserEdit(ctx, args.tripId, userId))) {
      throw new Error("You don't have permission to add media to this trip");
    }

    const now = Date.now();

    const mediaItemDocId = await ctx.db.insert("mediaItems", {
      userId,
      mediaItemId: args.mediaItemId,
      tripId: args.tripId,
      storageId: args.storageId,
      thumbnailStorageId: args.thumbnailStorageId,
      imageURL: args.imageURL,
      videoURL: args.videoURL,
      type: args.type,
      captureDate: args.captureDate,
      note: args.note,
      timestamp: args.timestamp,
      createdAt: now,
      updatedAt: now,
    });

    // Automatically set cover image if this is the first photo added to the trip
    if (args.type === "photo" && args.storageId) {
      const trip = await ctx.db
        .query("trips")
        .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
        .first();

      if (trip && !trip.coverImageStorageId) {
        await ctx.db.patch(trip._id, {
          coverImageStorageId: args.storageId,
          coverImageName: args.mediaItemId,
          updatedAt: now,
        });
      }
    }

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
    voiceNoteURL: v.optional(v.string()),
    gridPosition: v.object({
      column: v.number(),
      row: v.number(),
      width: v.number(),
      height: v.number(),
    }),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Check permission to edit trip
    if (!(await canUserEdit(ctx, args.tripId, userId))) {
      throw new Error("You don't have permission to add moments to this trip");
    }

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
      voiceNoteURL: args.voiceNoteURL,
      gridPosition: args.gridPosition,
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

// ============= DELETE MUTATIONS =============

// Delete a media item
export const deleteMediaItem = mutation({
  args: {
    mediaItemId: v.string(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Find the media item
    const mediaItem = await ctx.db
      .query("mediaItems")
      .withIndex("by_mediaItemId", (q) => q.eq("mediaItemId", args.mediaItemId))
      .first();

    if (!mediaItem) {
      throw new Error(`Media item not found: ${args.mediaItemId}`);
    }

    // Check permission to edit trip
    if (!(await canUserEdit(ctx, mediaItem.tripId, userId))) {
      throw new Error("You don't have permission to delete media from this trip");
    }

    // Remove this media item from all moments that reference it
    const moments = await ctx.db
      .query("moments")
      .withIndex("by_tripId", (q) => q.eq("tripId", mediaItem.tripId))
      .collect();

    for (const moment of moments) {
      if (moment.mediaItemIDs.includes(args.mediaItemId)) {
        const updatedMediaItemIDs = moment.mediaItemIDs.filter(
          (id) => id !== args.mediaItemId
        );
        await ctx.db.patch(moment._id, {
          mediaItemIDs: updatedMediaItemIDs,
          updatedAt: Date.now(),
        });
      }
    }

    // Delete file from storage if it exists
    if (mediaItem.storageId) {
      await ctx.storage.delete(mediaItem.storageId);
    }

    // Delete thumbnail from storage if it exists
    if (mediaItem.thumbnailStorageId) {
      await ctx.storage.delete(mediaItem.thumbnailStorageId);
    }

    // Delete the media item
    await ctx.db.delete(mediaItem._id);

    return { success: true };
  },
});

// Delete a moment
export const deleteMoment = mutation({
  args: {
    momentId: v.string(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Find the moment
    const moment = await ctx.db
      .query("moments")
      .withIndex("by_momentId", (q) => q.eq("momentId", args.momentId))
      .first();

    if (!moment) {
      throw new Error(`Moment not found: ${args.momentId}`);
    }

    // Check permission to edit trip
    if (!(await canUserEdit(ctx, moment.tripId, userId))) {
      throw new Error("You don't have permission to delete moments from this trip");
    }

    // Delete the moment
    await ctx.db.delete(moment._id);

    return { success: true };
  },
});

// ============= UPDATE MUTATIONS =============

// Update a media item
export const updateMediaItem = mutation({
  args: {
    mediaItemId: v.string(),
    note: v.optional(v.string()),
    captureDate: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Find the media item
    const mediaItem = await ctx.db
      .query("mediaItems")
      .withIndex("by_mediaItemId", (q) => q.eq("mediaItemId", args.mediaItemId))
      .first();

    if (!mediaItem) {
      throw new Error(`Media item not found: ${args.mediaItemId}`);
    }

    // Check permission to edit trip
    if (!(await canUserEdit(ctx, mediaItem.tripId, userId))) {
      throw new Error("You don't have permission to edit media in this trip");
    }

    const updates: any = {
      updatedAt: Date.now(),
    };

    if (args.note !== undefined) updates.note = args.note;
    if (args.captureDate !== undefined) updates.captureDate = args.captureDate;

    await ctx.db.patch(mediaItem._id, updates);
    return { success: true };
  },
});

// Update a moment
export const updateMoment = mutation({
  args: {
    momentId: v.string(),
    title: v.optional(v.string()),
    note: v.optional(v.string()),
    mediaItemIDs: v.optional(v.array(v.string())),
    date: v.optional(v.number()),
    placeName: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Find the moment
    const moment = await ctx.db
      .query("moments")
      .withIndex("by_momentId", (q) => q.eq("momentId", args.momentId))
      .first();

    if (!moment) {
      throw new Error(`Moment not found: ${args.momentId}`);
    }

    // Check permission to edit trip
    if (!(await canUserEdit(ctx, moment.tripId, userId))) {
      throw new Error("You don't have permission to edit moments in this trip");
    }

    const updates: any = {
      updatedAt: Date.now(),
    };

    if (args.title !== undefined) updates.title = args.title;
    if (args.note !== undefined) updates.note = args.note;
    if (args.mediaItemIDs !== undefined) updates.mediaItemIDs = args.mediaItemIDs;
    if (args.date !== undefined) updates.date = args.date;
    if (args.placeName !== undefined) updates.placeName = args.placeName;

    await ctx.db.patch(moment._id, updates);
    return { success: true };
  },
});

// Update moment grid position (for drag/resize operations)
export const updateMomentGridPosition = mutation({
  args: {
    momentId: v.string(),
    gridPosition: v.object({
      column: v.number(),
      row: v.number(),
      width: v.number(),
      height: v.number(),
    }),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Find the moment
    const moment = await ctx.db
      .query("moments")
      .withIndex("by_momentId", (q) => q.eq("momentId", args.momentId))
      .first();

    if (!moment) {
      throw new Error(`Moment not found: ${args.momentId}`);
    }

    // Check permission to edit trip
    if (!(await canUserEdit(ctx, moment.tripId, userId))) {
      throw new Error("You don't have permission to edit moments in this trip");
    }

    await ctx.db.patch(moment._id, {
      gridPosition: args.gridPosition,
      updatedAt: Date.now(),
    });

    return { success: true };
  },
});

// Batch update moment grid positions (for reflow operations)
export const batchUpdateMomentGridPositions = mutation({
  args: {
    updates: v.array(
      v.object({
        momentId: v.string(),
        gridPosition: v.object({
          column: v.number(),
          row: v.number(),
          width: v.number(),
          height: v.number(),
        }),
      })
    ),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);
    const now = Date.now();

    // Update all moments in batch
    for (const update of args.updates) {
      // Find the moment
      const moment = await ctx.db
        .query("moments")
        .withIndex("by_momentId", (q) => q.eq("momentId", update.momentId))
        .first();

      if (!moment) {
        throw new Error(`Moment not found: ${update.momentId}`);
      }

      // Check permission to edit trip
      if (!(await canUserEdit(ctx, moment.tripId, userId))) {
        throw new Error("You don't have permission to edit moments in this trip");
      }

      await ctx.db.patch(moment._id, {
        gridPosition: update.gridPosition,
        updatedAt: now,
      });
    }

    return { success: true };
  },
});

// ============= QUERIES =============

// Get public preview of a trip (for web preview page)
export const getPublicPreview = query({
  args: {
    shareSlug: v.optional(v.string()),
    shareCode: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    if (!args.shareSlug && !args.shareCode) {
      throw new Error("Either shareSlug or shareCode must be provided");
    }

    // Find trip by slug or code
    let trip;
    if (args.shareSlug) {
      trip = await ctx.db
        .query("trips")
        .withIndex("by_shareSlug", (q) => q.eq("shareSlug", args.shareSlug))
        .first();
    } else if (args.shareCode) {
      trip = await ctx.db
        .query("trips")
        .withIndex("by_shareCode", (q) => q.eq("shareCode", args.shareCode?.toUpperCase()))
        .first();
    }

    if (!trip) {
      return null;
    }

    // Check if sharing is enabled
    if (!trip.shareLinkEnabled) {
      return null;
    }

    // Get ALL moments for this trip to render the full canvas
    const moments = await ctx.db
      .query("moments")
      .withIndex("by_tripId", (q) => q.eq("tripId", trip.tripId))
      .collect();

    // Get media items for the moments
    const momentMediaItems = await Promise.all(
      moments.map(async (moment) => {
        const mediaItems = await ctx.db
          .query("mediaItems")
          .withIndex("by_tripId", (q) => q.eq("tripId", trip.tripId))
          .collect();

        // Filter to only media in this moment
        return mediaItems.filter((item) =>
          moment.mediaItemIDs.includes(item.mediaItemId)
        );
      })
    );

    // Get image URLs for each moment (up to 4 for collage)
    const momentsWithUrls = await Promise.all(
      moments.map(async (moment, index) => {
        const mediaItems = momentMediaItems[index] || [];
        const mediaUrls: (string | null)[] = [];

        // Get URLs for first 4 media items (for collage display)
        for (const mediaItem of mediaItems.slice(0, 4)) {
          if (mediaItem.storageId) {
            try {
              const url = await ctx.storage.getUrl(mediaItem.storageId);
              mediaUrls.push(url);
            } catch (error) {
              console.error(`Failed to get URL for storage ID ${mediaItem.storageId}:`, error);
              mediaUrls.push(null);
            }
          }
        }

        return {
          momentId: moment.momentId,
          title: moment.title,
          gridPosition: moment.gridPosition,
          mediaCount: mediaItems.length,
          mediaUrls,
        };
      })
    );

    return {
      trip: {
        tripId: trip.tripId,
        title: trip.title,
        startDate: trip.startDate,
        endDate: trip.endDate,
        shareSlug: trip.shareSlug,
        shareCode: trip.shareCode,
        coverImageStorageId: trip.coverImageStorageId,
        previewImageStorageId: trip.previewImageStorageId,
      },
      moments: momentsWithUrls,
      totalMoments: moments.length,
    };
  },
});

// ============= SHARING MUTATIONS =============

// Helper function to generate a URL-safe slug
function generateSlug(title: string): string {
  // Convert title to lowercase, remove special chars, replace spaces with dashes
  const baseSlug = title
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .substring(0, 20); // Limit length

  // Add random suffix for uniqueness
  const randomSuffix = Math.random().toString(36).substring(2, 6);
  return `${baseSlug}-${randomSuffix}`;
}

// Helper function to generate a human-readable share code
function generateShareCode(title: string): string {
  // Take first word of title (up to 6 chars) + 2 random digits
  const firstWord = title.split(' ')[0].toUpperCase().substring(0, 6);
  const randomDigits = Math.floor(10 + Math.random() * 90); // 2 digits (10-99)
  return `${firstWord}${randomDigits}`;
}

// Generate share link for a trip (enables sharing)
export const generateShareLink = mutation({
  args: {
    tripId: v.string(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Check if user is owner (only owner can enable sharing)
    if (!(await isOwner(ctx, args.tripId, userId))) {
      throw new Error("Only the trip owner can generate share links");
    }

    // Get the trip
    const trip = await ctx.db
      .query("trips")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .first();

    if (!trip) {
      throw new Error("Trip not found");
    }

    // If trip already has a share link, return existing
    if (trip.shareSlug && trip.shareCode) {
      return {
        shareSlug: trip.shareSlug,
        shareCode: trip.shareCode,
        url: `https://rewinded.app/trip/${trip.shareSlug}`,
      };
    }

    // Generate unique slug and code
    let shareSlug = generateSlug(trip.title);
    let shareCode = generateShareCode(trip.title);

    // Ensure slug is unique
    let existingSlug = await ctx.db
      .query("trips")
      .withIndex("by_shareSlug", (q) => q.eq("shareSlug", shareSlug))
      .first();

    while (existingSlug) {
      shareSlug = generateSlug(trip.title);
      existingSlug = await ctx.db
        .query("trips")
        .withIndex("by_shareSlug", (q) => q.eq("shareSlug", shareSlug))
        .first();
    }

    // Ensure code is unique
    let existingCode = await ctx.db
      .query("trips")
      .withIndex("by_shareCode", (q) => q.eq("shareCode", shareCode))
      .first();

    while (existingCode) {
      shareCode = generateShareCode(trip.title);
      existingCode = await ctx.db
        .query("trips")
        .withIndex("by_shareCode", (q) => q.eq("shareCode", shareCode))
        .first();
    }

    // Update trip with share link and enable sharing
    await ctx.db.patch(trip._id, {
      shareSlug,
      shareCode,
      shareLinkEnabled: true,
      updatedAt: Date.now(),
    });

    return {
      shareSlug,
      shareCode,
      url: `https://rewinded.app/trip/${shareSlug}`,
    };
  },
});

// Disable share link for a trip
export const disableShareLink = mutation({
  args: {
    tripId: v.string(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Check if user is owner
    if (!(await isOwner(ctx, args.tripId, userId))) {
      throw new Error("Only the trip owner can disable share links");
    }

    // Get the trip
    const trip = await ctx.db
      .query("trips")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .first();

    if (!trip) {
      throw new Error("Trip not found");
    }

    // Disable sharing (keep slug/code for re-enabling)
    await ctx.db.patch(trip._id, {
      shareLinkEnabled: false,
      updatedAt: Date.now(),
    });

    return { success: true };
  },
});

// Update a user's permission on a trip
export const updatePermission = mutation({
  args: {
    tripId: v.string(),
    userId: v.string(), // User whose permission to update
    newRole: v.union(v.literal("collaborator"), v.literal("viewer")),
  },
  handler: async (ctx, args) => {
    const currentUserId = await requireAuth(ctx);

    // Check if current user can manage permissions (owner or collaborator)
    const trip = await ctx.db
      .query("trips")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .first();

    if (!trip) {
      throw new Error("Trip not found");
    }

    // Only owner and collaborators can upgrade viewers
    const hasPermission = await isOwner(ctx, args.tripId, currentUserId) ||
                         await canUserEdit(ctx, args.tripId, currentUserId);

    if (!hasPermission) {
      throw new Error("You don't have permission to manage access for this trip");
    }

    // Can't change owner's role
    if (trip.ownerId === args.userId || trip.userId === args.userId) {
      throw new Error("Cannot change the owner's role");
    }

    // Find the permission to update
    const permission = await ctx.db
      .query("tripPermissions")
      .withIndex("by_tripId_userId", (q) =>
        q.eq("tripId", args.tripId).eq("userId", args.userId)
      )
      .first();

    if (!permission) {
      throw new Error("User does not have access to this trip");
    }

    // Update the permission
    await ctx.db.patch(permission._id, {
      role: args.newRole,
    });

    return { success: true };
  },
});

// Remove a user's access to a trip
export const removeAccess = mutation({
  args: {
    tripId: v.string(),
    userId: v.string(), // User to remove
  },
  handler: async (ctx, args) => {
    const currentUserId = await requireAuth(ctx);

    // Check if current user is the owner
    if (!(await isOwner(ctx, args.tripId, currentUserId))) {
      throw new Error("Only the trip owner can remove access");
    }

    const trip = await ctx.db
      .query("trips")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .first();

    if (!trip) {
      throw new Error("Trip not found");
    }

    // Can't remove owner
    if (trip.ownerId === args.userId || trip.userId === args.userId) {
      throw new Error("Cannot remove the owner from the trip");
    }

    // Find and delete the permission
    const permission = await ctx.db
      .query("tripPermissions")
      .withIndex("by_tripId_userId", (q) =>
        q.eq("tripId", args.tripId).eq("userId", args.userId)
      )
      .first();

    if (!permission) {
      throw new Error("User does not have access to this trip");
    }

    await ctx.db.delete(permission._id);

    return { success: true };
  },
});

// Get trips shared with the current user (where they're not the owner)
export const getSharedTrips = query({
  args: {},
  handler: async (ctx) => {
    const userId = await requireAuth(ctx);

    // Get all permissions for this user
    const permissions = await ctx.db
      .query("tripPermissions")
      .withIndex("by_userId", (q) => q.eq("userId", userId))
      .collect();

    // Get the trips for these permissions
    const trips = await Promise.all(
      permissions.map(async (permission) => {
        const trip = await ctx.db
          .query("trips")
          .withIndex("by_tripId", (q) => q.eq("tripId", permission.tripId))
          .first();

        if (!trip) return null;

        // Only return trips where user is NOT the owner
        if (trip.ownerId === userId || trip.userId === userId) {
          return null;
        }

        return {
          ...trip,
          userRole: permission.role,
        };
      })
    );

    // Filter out nulls and return
    return trips.filter((trip) => trip !== null);
  },
});

// Get all permissions for a trip (with user info)
export const getTripPermissions = query({
  args: {
    tripId: v.string(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    // Check if user has access to view permissions
    if (!(await canUserView(ctx, args.tripId, userId))) {
      throw new Error("You don't have access to this trip");
    }

    // Get all permissions for this trip
    const permissions = await ctx.db
      .query("tripPermissions")
      .withIndex("by_tripId", (q) => q.eq("tripId", args.tripId))
      .collect();

    // Get user info for each permission
    const permissionsWithUserInfo = await Promise.all(
      permissions.map(async (permission) => {
        const user = await ctx.db
          .query("users")
          .withIndex("by_clerkId", (q) => q.eq("clerkId", permission.userId))
          .first();

        return {
          id: permission._id,
          userId: permission.userId,
          role: permission.role,
          grantedVia: permission.grantedVia,
          invitedBy: permission.invitedBy,
          acceptedAt: permission.acceptedAt,
          user: user ? {
            name: user.name || null,
            email: user.email || null,
            imageUrl: user.imageUrl || null,
          } : null,
        };
      })
    );

    return permissionsWithUserInfo;
  },
});

// Join a trip via share link or code
export const joinTripViaLink = mutation({
  args: {
    // Either shareSlug or shareCode must be provided
    shareSlug: v.optional(v.string()),
    shareCode: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    if (!args.shareSlug && !args.shareCode) {
      throw new Error("Either shareSlug or shareCode must be provided");
    }

    // Find trip by slug or code
    let trip;
    if (args.shareSlug) {
      trip = await ctx.db
        .query("trips")
        .withIndex("by_shareSlug", (q) => q.eq("shareSlug", args.shareSlug))
        .first();
    } else if (args.shareCode) {
      trip = await ctx.db
        .query("trips")
        .withIndex("by_shareCode", (q) => q.eq("shareCode", args.shareCode?.toUpperCase()))
        .first();
    }

    if (!trip) {
      throw new Error("Trip not found. Please check the link or code.");
    }

    // Check if sharing is enabled
    if (!trip.shareLinkEnabled) {
      throw new Error("This trip is no longer accepting new members");
    }

    // Check if user already has access
    const existingPermission = await ctx.db
      .query("tripPermissions")
      .withIndex("by_tripId_userId", (q) =>
        q.eq("tripId", trip.tripId).eq("userId", userId)
      )
      .first();

    if (existingPermission) {
      // User already has access, just return trip info
      return {
        tripId: trip.tripId,
        alreadyMember: true,
      };
    }

    // Create viewer permission for the user
    const now = Date.now();
    await ctx.db.insert("tripPermissions", {
      tripId: trip.tripId,
      userId,
      role: "viewer",
      grantedVia: "share_link",
      invitedBy: trip.ownerId || trip.userId,
      acceptedAt: now,
      createdAt: now,
    });

    return {
      tripId: trip.tripId,
      alreadyMember: false,
    };
  },
});
