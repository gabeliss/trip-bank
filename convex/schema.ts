import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  // User table for Clerk integration
  users: defineTable({
    clerkId: v.string(), // Clerk user ID
    email: v.optional(v.string()),
    name: v.optional(v.string()),
    imageUrl: v.optional(v.string()),
    createdAt: v.number(),

    // Storage tracking
    storageUsedBytes: v.optional(v.number()), // Total bytes used by this user

    // Subscription (synced from RevenueCat)
    subscriptionTier: v.optional(v.union(v.literal("free"), v.literal("pro"))),
    subscriptionExpiresAt: v.optional(v.number()), // Timestamp when subscription expires
    revenueCatUserId: v.optional(v.string()), // RevenueCat customer ID
  }).index("by_clerkId", ["clerkId"]),

  trips: defineTable({
    // Core fields
    userId: v.string(), // DEPRECATED - use ownerId instead (keep for migration)
    ownerId: v.optional(v.string()), // Trip owner (optional for migration)
    tripId: v.string(), // UUID from Swift
    title: v.string(),
    startDate: v.number(), // Timestamp
    endDate: v.number(), // Timestamp
    coverImageName: v.optional(v.string()),
    coverImageStorageId: v.optional(v.id("_storage")), // Convex file storage

    // Sharing fields
    shareSlug: v.optional(v.string()), // URL-safe slug: "paris-2024-xl8k"
    shareCode: v.optional(v.string()), // Human-readable code: "PARIS24"
    shareLinkEnabled: v.optional(v.boolean()), // Can people join via link?
    previewImageStorageId: v.optional(v.id("_storage")), // Preview snapshot

    // Timestamps
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_tripId", ["tripId"])
    .index("by_userId", ["userId"])
    .index("by_userId_createdAt", ["userId", "createdAt"])
    .index("by_ownerId", ["ownerId"])
    .index("by_shareSlug", ["shareSlug"])
    .index("by_shareCode", ["shareCode"]),

  mediaItems: defineTable({
    // Core fields
    userId: v.string(), // Owner
    mediaItemId: v.string(), // UUID from Swift
    tripId: v.string(), // Reference to parent trip
    storageId: v.optional(v.id("_storage")), // Convex file storage ID
    thumbnailStorageId: v.optional(v.id("_storage")), // Thumbnail for videos
    imageURL: v.optional(v.string()),
    videoURL: v.optional(v.string()),
    type: v.union(v.literal("photo"), v.literal("video")),
    captureDate: v.optional(v.number()), // Timestamp
    note: v.optional(v.string()),
    timestamp: v.number(), // When added to trip

    // Storage tracking
    fileSize: v.optional(v.number()), // Size in bytes of the main file
    thumbnailSize: v.optional(v.number()), // Size in bytes of thumbnail (for videos)

    // Timestamps
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_tripId", ["tripId"])
    .index("by_mediaItemId", ["mediaItemId"])
    .index("by_userId", ["userId"]),

  moments: defineTable({
    // Core fields
    userId: v.string(), // Owner
    momentId: v.string(), // UUID from Swift
    tripId: v.string(), // Reference to parent trip
    title: v.string(),
    note: v.optional(v.string()),
    mediaItemIDs: v.array(v.string()), // Array of UUID strings
    timestamp: v.number(),

    // Enhanced metadata
    date: v.optional(v.number()), // Timestamp
    placeName: v.optional(v.string()),
    voiceNoteURL: v.optional(v.string()),

    // Visual layout properties
    gridPosition: v.object({
      column: v.number(), // 0 = left, 1 = right
      row: v.number(), // 0, 0.5, 1, 1.5, 2, 2.5, 3, etc.
      width: v.number(), // 1 or 2 (columns)
      height: v.number(), // 1, 1.5, 2, 2.5, 3, etc. (rows)
    }),

    // Timestamps
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_tripId", ["tripId"])
    .index("by_momentId", ["momentId"])
    .index("by_userId", ["userId"]),

  // Trip permissions for sharing & collaboration
  tripPermissions: defineTable({
    tripId: v.string(), // Foreign key to trips
    userId: v.string(), // Who has access (from users.clerkId)
    role: v.union(
      v.literal("owner"),
      v.literal("collaborator"),
      v.literal("viewer")
    ),
    grantedVia: v.union(
      v.literal("share_link"),
      v.literal("upgraded")
    ),
    invitedBy: v.string(), // userId who shared/upgraded
    acceptedAt: v.number(), // When user joined
    createdAt: v.number(),
  })
    .index("by_tripId", ["tripId"])
    .index("by_userId", ["userId"])
    .index("by_tripId_userId", ["tripId", "userId"]),
});
