import { mutation, query } from "./_generated/server";
import { v } from "convex/values";
import { requireAuth } from "./auth";

// Generate upload URL for a file
export const generateUploadUrl = mutation({
  args: {},
  handler: async (ctx) => {
    await requireAuth(ctx);
    return await ctx.storage.generateUploadUrl();
  },
});

// Get download URL for a file
export const getFileUrl = query({
  args: {
    storageId: v.id("_storage"),
  },
  handler: async (ctx, args) => {
    // Files are public once you have the storage ID
    // In a production app, you might want to verify ownership first
    return await ctx.storage.getUrl(args.storageId);
  },
});

// Delete a file from storage
export const deleteFile = mutation({
  args: {
    storageId: v.id("_storage"),
  },
  handler: async (ctx, args) => {
    await requireAuth(ctx);

    // In production, verify the user owns this file
    // by checking mediaItems or trips table

    await ctx.storage.delete(args.storageId);
    return { success: true };
  },
});
