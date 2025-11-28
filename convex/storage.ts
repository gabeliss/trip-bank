import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireAuth } from "./auth";

// Storage limits in bytes
export const STORAGE_LIMITS = {
  free: 500 * 1024 * 1024, // 500 MB
  pro: 10 * 1024 * 1024 * 1024, // 10 GB
} as const;

// ============= STORAGE QUERIES =============

// Get current user's storage usage and limits
export const getStorageUsage = query({
  args: {},
  handler: async (ctx) => {
    const userId = await requireAuth(ctx);

    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", userId))
      .first();

    if (!user) {
      return null;
    }

    const tier = user.subscriptionTier || "free";
    const limit = STORAGE_LIMITS[tier];
    const used = user.storageUsedBytes || 0;

    return {
      usedBytes: used,
      limitBytes: limit,
      tier,
      percentUsed: Math.min(100, (used / limit) * 100),
      remainingBytes: Math.max(0, limit - used),
      isAtLimit: used >= limit,
    };
  },
});

// Check if user can upload a file of given size
export const canUpload = query({
  args: {
    fileSize: v.number(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", userId))
      .first();

    if (!user) {
      return { canUpload: false, reason: "User not found" };
    }

    const tier = user.subscriptionTier || "free";
    const limit = STORAGE_LIMITS[tier];
    const used = user.storageUsedBytes || 0;

    if (used + args.fileSize > limit) {
      const remainingBytes = Math.max(0, limit - used);
      const remainingMB = (remainingBytes / (1024 * 1024)).toFixed(1);
      const fileSizeMB = (args.fileSize / (1024 * 1024)).toFixed(1);

      return {
        canUpload: false,
        reason: `Not enough storage. You have ${remainingMB} MB remaining, but this file is ${fileSizeMB} MB.`,
        remainingBytes,
        upgrade: tier === "free",
      };
    }

    return { canUpload: true };
  },
});

// ============= STORAGE MUTATIONS =============

// Add bytes to user's storage usage (called after successful upload)
export const addStorageUsage = mutation({
  args: {
    bytes: v.number(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", userId))
      .first();

    if (!user) {
      throw new Error("User not found");
    }

    const currentUsage = user.storageUsedBytes || 0;
    await ctx.db.patch(user._id, {
      storageUsedBytes: currentUsage + args.bytes,
    });

    return { newUsage: currentUsage + args.bytes };
  },
});

// Subtract bytes from user's storage usage (called after successful delete)
export const subtractStorageUsage = mutation({
  args: {
    bytes: v.number(),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", userId))
      .first();

    if (!user) {
      throw new Error("User not found");
    }

    const currentUsage = user.storageUsedBytes || 0;
    const newUsage = Math.max(0, currentUsage - args.bytes);

    await ctx.db.patch(user._id, {
      storageUsedBytes: newUsage,
    });

    return { newUsage };
  },
});

// Recalculate user's storage usage from all their media items
// Useful for fixing any discrepancies
export const recalculateStorageUsage = mutation({
  args: {},
  handler: async (ctx) => {
    const userId = await requireAuth(ctx);

    // Get all media items owned by this user
    const mediaItems = await ctx.db
      .query("mediaItems")
      .withIndex("by_userId", (q) => q.eq("userId", userId))
      .collect();

    // Sum up all file sizes
    let totalBytes = 0;
    for (const item of mediaItems) {
      totalBytes += item.fileSize || 0;
      totalBytes += item.thumbnailSize || 0;
    }

    // Update user's storage usage
    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", userId))
      .first();

    if (!user) {
      throw new Error("User not found");
    }

    await ctx.db.patch(user._id, {
      storageUsedBytes: totalBytes,
    });

    return { totalBytes, mediaItemCount: mediaItems.length };
  },
});

// ============= SUBSCRIPTION MUTATIONS =============

// Update user's subscription tier (called from iOS app after RevenueCat purchase)
export const updateSubscription = mutation({
  args: {
    tier: v.union(v.literal("free"), v.literal("pro")),
    expiresAt: v.optional(v.number()),
    revenueCatUserId: v.optional(v.string()),
  },
  handler: async (ctx, args) => {
    const userId = await requireAuth(ctx);

    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", userId))
      .first();

    if (!user) {
      throw new Error("User not found");
    }

    await ctx.db.patch(user._id, {
      subscriptionTier: args.tier,
      subscriptionExpiresAt: args.expiresAt,
      revenueCatUserId: args.revenueCatUserId,
    });

    return { success: true };
  },
});

// Get user's subscription info
export const getSubscription = query({
  args: {},
  handler: async (ctx) => {
    const userId = await requireAuth(ctx);

    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", userId))
      .first();

    if (!user) {
      return null;
    }

    const tier = user.subscriptionTier || "free";
    const expiresAt = user.subscriptionExpiresAt;
    const isExpired = expiresAt ? Date.now() > expiresAt : false;

    return {
      tier: isExpired ? "free" : tier,
      expiresAt,
      isExpired,
      storageLimit: STORAGE_LIMITS[isExpired ? "free" : tier],
    };
  },
});
