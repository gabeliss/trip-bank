import { Auth } from "convex/server";
import { QueryCtx, MutationCtx } from "./_generated/server";
import { mutation, query } from "./_generated/server";

// Helper to get authenticated user ID from Clerk
export async function getAuthUserId(
  ctx: QueryCtx | MutationCtx
): Promise<string | null> {
  const identity = await ctx.auth.getUserIdentity();
  if (!identity) {
    return null;
  }

  // Clerk provides the user ID in the subject field
  return identity.subject;
}

// Helper to require authentication
export async function requireAuth(
  ctx: QueryCtx | MutationCtx
): Promise<string> {
  const userId = await getAuthUserId(ctx);
  if (!userId) {
    throw new Error("Unauthorized: Must be logged in");
  }
  return userId;
}

// Helper to get or create user in database
export async function getOrCreateUser(ctx: MutationCtx) {
  const identity = await ctx.auth.getUserIdentity();
  if (!identity) {
    throw new Error("Unauthorized");
  }

  const clerkId = identity.subject;

  // Check if user exists
  const existingUser = await ctx.db
    .query("users")
    .withIndex("by_clerkId", (q) => q.eq("clerkId", clerkId))
    .first();

  if (existingUser) {
    return existingUser._id;
  }

  // Create new user
  const userId = await ctx.db.insert("users", {
    clerkId,
    email: identity.email,
    name: identity.name,
    imageUrl: identity.pictureUrl,
    createdAt: Date.now(),
  });

  return userId;
}

// Mutation to sync user from Clerk to Convex database
// Call this after user signs in to ensure they exist in the database
export const syncUser = mutation({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      throw new Error("Unauthorized");
    }

    const clerkId = identity.subject;

    // Check if user exists
    const existingUser = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", clerkId))
      .first();

    if (existingUser) {
      // Update existing user with latest Clerk data
      await ctx.db.patch(existingUser._id, {
        email: identity.email,
        name: identity.name,
        imageUrl: identity.pictureUrl,
      });

      // Return updated user
      const user = await ctx.db.get(existingUser._id);
      return user;
    }

    // Create new user if doesn't exist
    const userId = await ctx.db.insert("users", {
      clerkId,
      email: identity.email,
      name: identity.name,
      imageUrl: identity.pictureUrl,
      createdAt: Date.now(),
    });

    // Return the user document
    const user = await ctx.db.get(userId);
    return user;
  },
});

// Query to get current user info
export const getCurrentUser = query({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) {
      return null;
    }

    const user = await ctx.db
      .query("users")
      .withIndex("by_clerkId", (q) => q.eq("clerkId", identity.subject))
      .first();

    return user;
  },
});
