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
  }).index("by_clerkId", ["clerkId"]),

  trips: defineTable({
    // Core fields
    userId: v.string(), // Owner of the trip
    tripId: v.string(), // UUID from Swift
    title: v.string(),
    startDate: v.number(), // Timestamp
    endDate: v.number(), // Timestamp
    coverImageName: v.optional(v.string()),
    coverImageStorageId: v.optional(v.id("_storage")), // Convex file storage

    // Timestamps
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_tripId", ["tripId"])
    .index("by_userId", ["userId"])
    .index("by_userId_createdAt", ["userId", "createdAt"]),

  mediaItems: defineTable({
    // Core fields
    userId: v.string(), // Owner
    mediaItemId: v.string(), // UUID from Swift
    tripId: v.string(), // Reference to parent trip
    imageName: v.string(),
    imageURL: v.optional(v.string()),
    videoURL: v.optional(v.string()),
    storageId: v.optional(v.id("_storage")), // Convex file storage ID
    type: v.union(v.literal("photo"), v.literal("video")),
    captureDate: v.optional(v.number()), // Timestamp
    note: v.optional(v.string()),
    timestamp: v.number(), // When added to trip

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
    eventName: v.optional(v.string()),
    voiceNoteURL: v.optional(v.string()),

    // Visual layout properties
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

    // Timestamps
    createdAt: v.number(),
    updatedAt: v.number(),
  })
    .index("by_tripId", ["tripId"])
    .index("by_momentId", ["momentId"])
    .index("by_userId", ["userId"]),
});
