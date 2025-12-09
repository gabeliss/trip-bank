import Foundation
import UIKit
import Clerk
import ConvexMobile
import Combine

// MARK: - Convex Client

/// Wrapper around the official ConvexMobile SDK that provides both:
/// 1. Real-time subscriptions via WebSocket
/// 2. HTTP-based mutations for data changes
@MainActor
class ConvexClient {
    static let shared = ConvexClient()

    #if DEBUG
    private let baseURL = "https://flippant-mongoose-94.convex.cloud"
    #else
    private let baseURL = "https://silent-hare-226.convex.cloud"
    #endif
    private var convexClient: ConvexClientWithAuth<String>!
    private var cancellables = Set<AnyCancellable>()

    // URL cache for storage URLs
    private let urlCache = ConvexURLCache()

    private init() {
        // Initialize the Convex client with Clerk authentication
        let authProvider = ClerkAuthProvider()
        convexClient = ConvexClientWithAuth(
            deploymentUrl: baseURL,
            authProvider: authProvider
        )
    }

    // MARK: - Authentication

    /// Ensure authentication before subscribing
    func ensureLoggedIn() async {
        do {
            // Try to login from cache or trigger new login
            let _ = try await convexClient.loginFromCache()
            print("✅ [Convex] Authenticated from cache")
        } catch {
            print("⚠️ [Convex] Cache login failed, trying full login")
            do {
                let _ = try await convexClient.login()
                print("✅ [Convex] Authenticated successfully")
            } catch {
                print("❌ [Convex] Authentication failed: \(error)")
            }
        }
    }

    /// Ensure user is authenticated (call before mutations)
    private func ensureAuthenticated() async throws {
        // Authentication is handled automatically by the SDK
        // If not authenticated, the SDK will call login() automatically
    }

    // MARK: - Real-Time Subscriptions

    /// Subscribe to a Convex query with real-time updates
    /// Returns a Combine publisher that emits new values when backend data changes
    func subscribe<T: Decodable>(
        to query: String,
        with args: [String: (any ConvexEncodable)?] = [:],
        yielding type: T.Type
    ) -> AnyPublisher<T, ClientError> {
        return convexClient.subscribe(to: query, with: args, yielding: type)
    }

    // MARK: - Mutations (HTTP-based for backward compatibility)

    /// Call a Convex mutation
    private func mutation<T: Decodable>(_ functionName: String, args: [String: Any] = [:]) async throws -> T {
        try await ensureAuthenticated()

        let url = URL(string: "\(baseURL)/api/mutation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token
        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "path": functionName,
            "args": args
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ConvexError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw ConvexError.httpError(statusCode: httpResponse.statusCode)
        }

        let convexResponse = try JSONDecoder().decode(ConvexResponse<T>.self, from: data)

        if convexResponse.status == "success" {
            return convexResponse.value
        } else {
            throw ConvexError.convexError(message: convexResponse.errorMessage ?? "Unknown error")
        }
    }

    private func getAuthToken() async -> String? {
        guard let session = await Clerk.shared.session else { return nil }
        do {
            guard let tokenResource = try await session.getToken(.init(template: "convex")) else {
                return nil
            }
            return tokenResource.jwt
        } catch {
            return nil
        }
    }

    // MARK: - User Management

    func syncUser() async throws -> ConvexUser? {
        return try await mutation("auth:syncUser", args: [:])
    }

    func deleteAccount() async throws {
        let _: DeleteResponse = try await mutation("users:deleteAccount", args: [:])
    }

    // MARK: - Trip Mutations

    func createTrip(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        coverImageName: String? = nil
    ) async throws -> String {
        var args: [String: Any] = [
            "tripId": id,
            "title": title,
            "startDate": Int(startDate.timeIntervalSince1970 * 1000),
            "endDate": Int(endDate.timeIntervalSince1970 * 1000)
        ]
        if let coverImageName = coverImageName {
            args["coverImageName"] = coverImageName
        }
        return try await mutation("trips/trips:createTrip", args: args)
    }

    func updateTrip(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        coverImageName: String? = nil,
        coverImageStorageId: String? = nil
    ) async throws -> String {
        var args: [String: Any] = [
            "tripId": id,
            "title": title,
            "startDate": Int(startDate.timeIntervalSince1970 * 1000),
            "endDate": Int(endDate.timeIntervalSince1970 * 1000)
        ]

        if let coverImageName = coverImageName {
            args["coverImageName"] = coverImageName
        }
        if let coverImageStorageId = coverImageStorageId {
            args["coverImageStorageId"] = coverImageStorageId
        }

        return try await mutation("trips/trips:updateTrip", args: args)
    }

    func deleteTrip(id: String) async throws -> DeleteResponse {
        return try await mutation("trips/trips:deleteTrip", args: ["tripId": id])
    }

    // MARK: - Media Item Mutations

    func addMediaItem(
        id: String,
        tripId: String,
        imageURL: String? = nil,
        videoURL: String? = nil,
        storageId: String? = nil,
        thumbnailStorageId: String? = nil,
        type: String,
        captureDate: Date?,
        note: String?,
        timestamp: TimeInterval,
        fileSize: Int? = nil,
        thumbnailSize: Int? = nil
    ) async throws -> String {
        var args: [String: Any] = [
            "mediaItemId": id,
            "tripId": tripId,
            "type": type,
            "timestamp": Int(timestamp * 1000)
        ]

        if let imageURL = imageURL { args["imageURL"] = imageURL }
        if let videoURL = videoURL { args["videoURL"] = videoURL }
        if let storageId = storageId { args["storageId"] = storageId }
        if let thumbnailStorageId = thumbnailStorageId { args["thumbnailStorageId"] = thumbnailStorageId }
        if let captureDate = captureDate { args["captureDate"] = Int(captureDate.timeIntervalSince1970 * 1000) }
        if let note = note { args["note"] = note }
        if let fileSize = fileSize { args["fileSize"] = fileSize }
        if let thumbnailSize = thumbnailSize { args["thumbnailSize"] = thumbnailSize }

        return try await mutation("trips/media:addMediaItem", args: args)
    }

    func updateMediaItem(
        id: String,
        note: String?,
        captureDate: Date?
    ) async throws -> DeleteResponse {
        var args: [String: Any] = ["mediaItemId": id]
        if let note = note { args["note"] = note }
        if let captureDate = captureDate { args["captureDate"] = Int(captureDate.timeIntervalSince1970 * 1000) }

        return try await mutation("trips/media:updateMediaItem", args: args)
    }

    func deleteMediaItem(id: String) async throws -> DeleteResponse {
        return try await mutation("trips/media:deleteMediaItem", args: ["mediaItemId": id])
    }

    // MARK: - Moment Mutations

    func addMoment(
        id: String,
        tripId: String,
        title: String,
        note: String?,
        mediaItemIDs: [String],
        timestamp: TimeInterval,
        date: Date?,
        placeName: String?,
        voiceNoteURL: String?,
        gridPosition: GridPosition
    ) async throws -> String {
        var args: [String: Any] = [
            "momentId": id,
            "tripId": tripId,
            "title": title,
            "mediaItemIDs": mediaItemIDs,
            "timestamp": Int(timestamp * 1000),
            "gridPosition": [
                "column": gridPosition.column,
                "row": gridPosition.row,
                "width": gridPosition.width,
                "height": gridPosition.height
            ]
        ]

        if let note = note { args["note"] = note }
        if let date = date { args["date"] = Int(date.timeIntervalSince1970 * 1000) }
        if let placeName = placeName { args["placeName"] = placeName }
        if let voiceNoteURL = voiceNoteURL { args["voiceNoteURL"] = voiceNoteURL }

        return try await mutation("trips/moments:addMoment", args: args)
    }

    func updateMoment(
        id: String,
        title: String,
        note: String?,
        mediaItemIDs: [String],
        date: Date?,
        placeName: String?
    ) async throws -> DeleteResponse {
        var args: [String: Any] = [
            "momentId": id,
            "title": title,
            "mediaItemIDs": mediaItemIDs
        ]

        if let note = note { args["note"] = note }
        if let date = date { args["date"] = Int(date.timeIntervalSince1970 * 1000) }
        if let placeName = placeName { args["placeName"] = placeName }

        return try await mutation("trips/moments:updateMoment", args: args)
    }

    func deleteMoment(id: String) async throws -> DeleteResponse {
        return try await mutation("trips/moments:deleteMoment", args: ["momentId": id])
    }

    func batchUpdateMomentGridPositions(updates: [(String, GridPosition)]) async throws -> DeleteResponse {
        let updatesArray = updates.map { (momentId, gridPosition) in
            return [
                "momentId": momentId,
                "gridPosition": [
                    "column": gridPosition.column,
                    "row": gridPosition.row,
                    "width": gridPosition.width,
                    "height": gridPosition.height
                ]
            ] as [String : Any]
        }

        let args: [String: Any] = ["updates": updatesArray]
        return try await mutation("trips/moments:batchUpdateMomentGridPositions", args: args)
    }

    // MARK: - Sharing & Permissions

    func generateShareLink(tripId: String) async throws -> ShareLinkResponse {
        return try await mutation("trips/sharing:generateShareLink", args: ["tripId": tripId])
    }

    func joinTripViaLink(shareSlug: String?, shareCode: String?) async throws -> JoinTripResponse {
        var args: [String: Any] = [:]
        if let shareSlug = shareSlug { args["shareSlug"] = shareSlug }
        if let shareCode = shareCode { args["shareCode"] = shareCode }
        return try await mutation("trips/sharing:joinTripViaLink", args: args)
    }

    func updatePermission(tripId: String, userId: String, newRole: String) async throws -> DeleteResponse {
        let args: [String: Any] = [
            "tripId": tripId,
            "userId": userId,
            "newRole": newRole
        ]
        return try await mutation("trips/sharing:updatePermission", args: args)
    }

    func removeAccess(tripId: String, userId: String) async throws -> DeleteResponse {
        let args: [String: Any] = [
            "tripId": tripId,
            "userId": userId
        ]
        return try await mutation("trips/sharing:removeAccess", args: args)
    }

    func getTripPermissions(tripId: String) async throws -> [TripPermissionWithUser] {
        // For permissions, we still use HTTP query for now
        // Could be converted to subscription if needed
        let url = URL(string: "\(baseURL)/api/query")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "path": "trips/sharing:getTripPermissions",
            "args": ["tripId": tripId]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ConvexError.invalidResponse
        }

        let convexResponse = try JSONDecoder().decode(ConvexResponse<[TripPermissionWithUser]>.self, from: data)

        if convexResponse.status == "success" {
            return convexResponse.value
        } else {
            throw ConvexError.convexError(message: convexResponse.errorMessage ?? "Unknown error")
        }
    }

    // MARK: - File Storage

    func generateUploadUrl() async throws -> String {
        return try await mutation("files:generateUploadUrl", args: [:])
    }

    func getFileUrl(storageId: String) async throws -> String {
        // Check cache first
        if let cached = await urlCache.get(storageId) {
            return cached
        }

        // Use HTTP query instead of mutation since getFileUrl is a query
        let requestURL = URL(string: "\(baseURL)/api/query")!
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "path": "files:getFileUrl",
            "args": ["storageId": storageId]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ConvexError.invalidResponse
        }

        let convexResponse = try JSONDecoder().decode(ConvexResponse<String>.self, from: data)

        if convexResponse.status == "success" {
            let url = convexResponse.value
            // Cache the URL
            await urlCache.set(storageId, value: url)
            return url
        } else {
            throw ConvexError.convexError(message: convexResponse.errorMessage ?? "Unknown error")
        }
    }

    /// Result of an upload including storage ID and file size
    struct UploadResult {
        let storageId: String
        let fileSize: Int
    }

    /// Upload an image to Convex storage
    func uploadImage(_ image: UIImage) async throws -> String {
        let result = try await uploadImageWithSize(image)
        return result.storageId
    }

    /// Upload an image to Convex storage and return size
    func uploadImageWithSize(_ image: UIImage) async throws -> UploadResult {
        // 1. Compress image
        guard let imageData = compressImage(image) else {
            throw ConvexError.convexError(message: "Failed to compress image")
        }

        // 2. Generate upload URL
        let uploadUrl = try await generateUploadUrl()

        // 3. Upload the file
        guard let url = URL(string: uploadUrl) else {
            throw ConvexError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = imageData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ConvexError.convexError(message: "Failed to upload image")
        }

        // 4. Parse response to get storage ID
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        return UploadResult(storageId: uploadResponse.storageId, fileSize: imageData.count)
    }

    /// Upload a video to Convex storage
    func uploadVideo(_ videoURL: URL) async throws -> String {
        let result = try await uploadVideoWithSize(videoURL)
        return result.storageId
    }

    /// Upload a video to Convex storage and return size
    func uploadVideoWithSize(_ videoURL: URL) async throws -> UploadResult {
        // 1. Read video data
        guard let videoData = try? Data(contentsOf: videoURL) else {
            throw ConvexError.convexError(message: "Failed to read video file")
        }

        // 2. Generate upload URL
        let uploadUrl = try await generateUploadUrl()

        // 3. Upload the file
        guard let url = URL(string: uploadUrl) else {
            throw ConvexError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")
        request.httpBody = videoData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ConvexError.convexError(message: "Failed to upload video")
        }

        // 4. Parse response to get storage ID
        let uploadResponse = try JSONDecoder().decode(UploadResponse.self, from: data)
        return UploadResult(storageId: uploadResponse.storageId, fileSize: videoData.count)
    }

    // MARK: - Storage & Subscription

    /// Get current user's storage usage
    func getStorageUsage() async throws -> StorageUsageResponse? {
        let url = URL(string: "\(baseURL)/api/query")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "path": "storage:getStorageUsage",
            "args": [:]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ConvexError.invalidResponse
        }

        let convexResponse = try JSONDecoder().decode(ConvexResponse<StorageUsageResponse?>.self, from: data)

        if convexResponse.status == "success" {
            return convexResponse.value
        } else {
            throw ConvexError.convexError(message: convexResponse.errorMessage ?? "Unknown error")
        }
    }

    /// Update user's subscription (called after RevenueCat purchase)
    func updateSubscription(tier: String, expiresAt: Int?, revenueCatUserId: String?) async throws {
        var args: [String: Any] = ["tier": tier]
        if let expiresAt = expiresAt { args["expiresAt"] = expiresAt }
        if let revenueCatUserId = revenueCatUserId { args["revenueCatUserId"] = revenueCatUserId }

        let _: SuccessResponse = try await mutation("storage:updateSubscription", args: args)
    }

    /// Recalculate storage usage (useful for fixing discrepancies)
    func recalculateStorageUsage() async throws -> RecalculateResponse {
        return try await mutation("storage:recalculateStorageUsage", args: [:])
    }

    /// Compress image to reasonable size for storage
    private func compressImage(_ image: UIImage, maxDimension: CGFloat = 1024, quality: CGFloat = 0.8) -> Data? {
        // Calculate new size maintaining aspect ratio
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)

        // Only resize if image is larger than max dimension
        let newSize: CGSize
        if ratio < 1.0 {
            newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        } else {
            newSize = size
        }

        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()

        // Compress to JPEG
        return resizedImage?.jpegData(compressionQuality: quality)
    }
}

// MARK: - URL Cache Actor

actor ConvexURLCache {
    private var cache: [String: String] = [:]

    func get(_ key: String) -> String? {
        return cache[key]
    }

    func set(_ key: String, value: String) {
        cache[key] = value
    }
}
