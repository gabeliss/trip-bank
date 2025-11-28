/* eslint-disable */
/**
 * Generated `api` utility.
 *
 * THIS CODE IS AUTOMATICALLY GENERATED.
 *
 * To regenerate, run `npx convex dev`.
 * @module
 */

import type * as auth from "../auth.js";
import type * as files from "../files.js";
import type * as storage from "../storage.js";
import type * as trips_media from "../trips/media.js";
import type * as trips_moments from "../trips/moments.js";
import type * as trips_permissions from "../trips/permissions.js";
import type * as trips_public from "../trips/public.js";
import type * as trips_sharing from "../trips/sharing.js";
import type * as trips_trips from "../trips/trips.js";

import type {
  ApiFromModules,
  FilterApi,
  FunctionReference,
} from "convex/server";

declare const fullApi: ApiFromModules<{
  auth: typeof auth;
  files: typeof files;
  storage: typeof storage;
  "trips/media": typeof trips_media;
  "trips/moments": typeof trips_moments;
  "trips/permissions": typeof trips_permissions;
  "trips/public": typeof trips_public;
  "trips/sharing": typeof trips_sharing;
  "trips/trips": typeof trips_trips;
}>;

/**
 * A utility for referencing Convex functions in your app's public API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = api.myModule.myFunction;
 * ```
 */
export declare const api: FilterApi<
  typeof fullApi,
  FunctionReference<any, "public">
>;

/**
 * A utility for referencing Convex functions in your app's internal API.
 *
 * Usage:
 * ```js
 * const myFunctionReference = internal.myModule.myFunction;
 * ```
 */
export declare const internal: FilterApi<
  typeof fullApi,
  FunctionReference<any, "internal">
>;

export declare const components: {};
