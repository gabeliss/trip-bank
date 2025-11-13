import Foundation
import UIKit
import Clerk

class ConvexClient {
    static let shared = ConvexClient()

    // Your Convex deployment URL
    private let baseURL = "https://flippant-mongoose-94.convex.cloud"
    private let authTokenKey = "convex_auth_token"

    private init() {}

    // MARK: - Auth Token Helper

    private func getAuthToken() async -> String? {
        // Get token from Clerk with Convex template
        guard let session = await Clerk.shared.session else {
            return nil
        }

        do {
            // Request token with Convex JWT template
            guard let tokenResource = try await session.getToken(.init(template: "convex")) else {
                return nil
            }
            return tokenResource.jwt
        } catch {
            print("❌ [Convex] Failed to get Clerk token: \(error)")
            return nil
        }
    }

    // MARK: - Generic Request Methods

    private func callQuery<T: Decodable>(_ functionName: String, args: [String: Any] = [:]) async throws -> T {
        let url = URL(string: "\(baseURL)/api/query")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
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

        // Convex API returns {"status": "success", "value": <result>}
        let convexResponse = try JSONDecoder().decode(ConvexResponse<T>.self, from: data)

        if convexResponse.status == "success" {
            return convexResponse.value
        } else {
            throw ConvexError.convexError(message: convexResponse.errorMessage ?? "Unknown error")
        }
    }

    private func callMutation<T: Decodable>(_ functionName: String, args: [String: Any] = [:]) async throws -> T {
        let url = URL(string: "\(baseURL)/api/mutation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
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

    // MARK: - Trip Mutations

    func createTrip(id: String, title: String, startDate: Date, endDate: Date, coverImageName: String? = nil) async throws -> String {
        var args: [String: Any] = [
            "tripId": id,
            "title": title,
            "startDate": startDate.timeIntervalSince1970 * 1000, // Convert to milliseconds
            "endDate": endDate.timeIntervalSince1970 * 1000
        ]

        // Only include coverImageName if it has a value
        if let coverImageName = coverImageName {
            args["coverImageName"] = coverImageName
        }

        return try await callMutation("trips:createTrip", args: args)
    }

    func updateTrip(id: String, title: String? = nil, startDate: Date? = nil, endDate: Date? = nil, coverImageName: String? = nil) async throws -> String {
        var args: [String: Any] = [
            "tripId": id
        ]

        if let title = title {
            args["title"] = title
        }
        if let startDate = startDate {
            args["startDate"] = startDate.timeIntervalSince1970 * 1000
        }
        if let endDate = endDate {
            args["endDate"] = endDate.timeIntervalSince1970 * 1000
        }
        if let coverImageName = coverImageName {
            args["coverImageName"] = coverImageName
        }

        return try await callMutation("trips:updateTrip", args: args)
    }

    func deleteTrip(id: String) async throws -> DeleteResponse {
        let args: [String: Any] = [
            "tripId": id
        ]

        return try await callMutation("trips:deleteTrip", args: args)
    }

    // MARK: - Auth Mutations

    func syncUser() async throws -> ConvexUser? {
        return try await callMutation("auth:syncUser")
    }

    // MARK: - File Storage

    /// Generate an upload URL for file storage
    func generateUploadUrl() async throws -> String {
        return try await callMutation("files:generateUploadUrl")
    }

    /// Upload an image to Convex storage
    func uploadImage(_ image: UIImage) async throws -> String {
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
        return uploadResponse.storageId
    }

    /// Get download URL for a stored file
    func getFileUrl(storageId: String) async throws -> String {
        let args: [String: Any] = [
            "storageId": storageId
        ]
        return try await callQuery("files:getFileUrl", args: args)
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
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Convert to JPEG with compression
        return resizedImage?.jpegData(compressionQuality: quality)
    }

    // MARK: - Trip Queries

    func getAllTrips() async throws -> [ConvexTrip] {
        return try await callQuery("trips:getAllTrips")
    }

    func getTrip(id: String) async throws -> TripWithDetails? {
        let args: [String: Any] = [
            "tripId": id
        ]

        return try await callQuery("trips:getTrip", args: args)
    }

    // MARK: - Media Item Mutations

    func addMediaItem(id: String, tripId: String, imageName: String, imageURL: String? = nil, videoURL: String? = nil, storageId: String? = nil, type: String, captureDate: Date? = nil, note: String? = nil, timestamp: Date) async throws -> String {
        var args: [String: Any] = [
            "mediaItemId": id,
            "tripId": tripId,
            "imageName": imageName,
            "type": type,
            "timestamp": timestamp.timeIntervalSince1970 * 1000
        ]

        if let imageURL = imageURL {
            args["imageURL"] = imageURL
        }
        if let videoURL = videoURL {
            args["videoURL"] = videoURL
        }
        if let storageId = storageId {
            args["storageId"] = storageId
        }
        if let captureDate = captureDate {
            args["captureDate"] = captureDate.timeIntervalSince1970 * 1000
        }
        if let note = note {
            args["note"] = note
        }

        return try await callMutation("trips:addMediaItem", args: args)
    }

    // MARK: - Moment Mutations

    func addMoment(id: String, tripId: String, title: String, note: String? = nil, mediaItemIDs: [String], timestamp: Date, date: Date? = nil, placeName: String? = nil, eventName: String? = nil, voiceNoteURL: String? = nil, importance: String, layoutPosition: CGPoint? = nil, layoutSize: String? = nil) async throws -> String {
        var args: [String: Any] = [
            "momentId": id,
            "tripId": tripId,
            "title": title,
            "mediaItemIDs": mediaItemIDs,
            "timestamp": timestamp.timeIntervalSince1970 * 1000,
            "importance": importance
        ]

        if let note = note {
            args["note"] = note
        }
        if let date = date {
            args["date"] = date.timeIntervalSince1970 * 1000
        }
        if let placeName = placeName {
            args["placeName"] = placeName
        }
        if let eventName = eventName {
            args["eventName"] = eventName
        }
        if let voiceNoteURL = voiceNoteURL {
            args["voiceNoteURL"] = voiceNoteURL
        }
        if let layoutPosition = layoutPosition {
            args["layoutPosition"] = [
                "x": layoutPosition.x,
                "y": layoutPosition.y
            ]
        }
        if let layoutSize = layoutSize {
            args["layoutSize"] = layoutSize
        }

        return try await callMutation("trips:addMoment", args: args)
    }
}

// MARK: - Response Types

struct ConvexUser: Decodable {
    let _id: String
    let _creationTime: Double
    let clerkId: String
    let email: String?
    let name: String?
    let imageUrl: String?
    let createdAt: Double
}

struct ConvexResponse<T: Decodable>: Decodable {
    let status: String
    let value: T
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case status
        case value
        case errorMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decode(String.self, forKey: .status)

        if status == "success" {
            value = try container.decode(T.self, forKey: .value)
            errorMessage = nil
        } else {
            // For error cases, we need a default value
            // This is a bit hacky but works for our error handling
            errorMessage = try? container.decode(String.self, forKey: .errorMessage)

            // Try to decode as empty value for error cases
            if let emptyValue = try? container.decode(T.self, forKey: .value) {
                value = emptyValue
            } else {
                throw ConvexError.decodingError
            }
        }
    }
}

struct ConvexTrip: Decodable {
    let _id: String
    let _creationTime: Double
    let tripId: String
    let title: String
    let startDate: Double
    let endDate: Double
    let coverImageName: String?
    let createdAt: Double
    let updatedAt: Double
}

struct ConvexMediaItem: Decodable {
    let _id: String
    let _creationTime: Double
    let mediaItemId: String
    let tripId: String
    let imageName: String
    let storageId: String?
    let imageURL: String?
    let videoURL: String?
    let type: String
    let captureDate: Double?
    let note: String?
    let timestamp: Double
    let createdAt: Double
    let updatedAt: Double
}

struct ConvexMoment: Decodable {
    let _id: String
    let _creationTime: Double
    let momentId: String
    let tripId: String
    let title: String
    let note: String?
    let mediaItemIDs: [String]
    let timestamp: Double
    let date: Double?
    let placeName: String?
    let eventName: String?
    let voiceNoteURL: String?
    let importance: String
    let layoutPosition: LayoutPosition?
    let layoutSize: String?
    let createdAt: Double
    let updatedAt: Double

    struct LayoutPosition: Decodable {
        let x: Double
        let y: Double
    }
}

struct TripWithDetails: Decodable {
    let trip: ConvexTrip
    let mediaItems: [ConvexMediaItem]
    let moments: [ConvexMoment]
}

struct DeleteResponse: Decodable {
    let success: Bool
}

struct UploadResponse: Decodable {
    let storageId: String
}

// MARK: - Errors

enum ConvexError: Error, LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case convexError(message: String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .convexError(let message):
            return "Convex error: \(message)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Extension to convert Convex types to local types

extension ConvexTrip {
    func toTrip() -> Trip {
        return Trip(
            id: UUID(uuidString: tripId) ?? UUID(),
            title: title,
            startDate: Date(timeIntervalSince1970: startDate / 1000),
            endDate: Date(timeIntervalSince1970: endDate / 1000),
            coverImageName: coverImageName,
            mediaItems: [],
            moments: []
        )
    }
}

extension ConvexMediaItem {
    func toMediaItem() -> MediaItem {
        return MediaItem(
            id: UUID(uuidString: mediaItemId) ?? UUID(),
            imageName: imageName,
            storageId: storageId,
            imageURL: imageURL.flatMap { URL(string: $0) },
            videoURL: videoURL.flatMap { URL(string: $0) },
            type: type == "video" ? .video : .photo,
            captureDate: captureDate.map { Date(timeIntervalSince1970: $0 / 1000) },
            note: note,
            timestamp: Date(timeIntervalSince1970: timestamp / 1000)
        )
    }
}

extension ConvexMoment {
    func toMoment() -> Moment {
        let pos: CGPoint? = layoutPosition.map { CGPoint(x: $0.x, y: $0.y) }
        let size: MomentSize? = layoutSize.flatMap { MomentSize(rawValue: $0) }
        let imp = MomentImportance(rawValue: importance) ?? .medium

        return Moment(
            id: UUID(uuidString: momentId) ?? UUID(),
            title: title,
            note: note,
            mediaItemIDs: mediaItemIDs.compactMap { UUID(uuidString: $0) },
            timestamp: Date(timeIntervalSince1970: timestamp / 1000),
            date: date.map { Date(timeIntervalSince1970: $0 / 1000) },
            placeName: placeName,
            eventName: eventName,
            voiceNoteURL: voiceNoteURL,
            importance: imp,
            layoutPosition: pos,
            layoutSize: size
        )
    }
}
