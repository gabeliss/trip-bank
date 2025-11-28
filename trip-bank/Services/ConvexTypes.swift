import Foundation

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
    let coverImageStorageId: String?
    let createdAt: Double
    let updatedAt: Double
    // Sharing fields
    let ownerId: String?
    let shareSlug: String?
    let shareCode: String?
    let shareLinkEnabled: Bool?
    let userRole: String? // Role in shared trips
    let joinedAt: Double? // When user joined (for shared trips)
}

struct ConvexMediaItem: Decodable {
    let _id: String
    let _creationTime: Double
    let mediaItemId: String
    let tripId: String
    let storageId: String?
    let thumbnailStorageId: String?
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
    let voiceNoteURL: String?
    let gridPosition: GridPositionDTO
    let createdAt: Double
    let updatedAt: Double

    struct GridPositionDTO: Decodable {
        let column: Double
        let row: Double
        let width: Double
        let height: Double
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

struct ShareLinkResponse: Decodable {
    let shareSlug: String
    let shareCode: String
    let url: String
}

struct JoinTripResponse: Decodable {
    let tripId: String
    let alreadyMember: Bool
}

// MARK: - Storage & Subscription Types

struct StorageUsageResponse: Decodable {
    let usedBytes: Int
    let limitBytes: Int
    let tier: String
    let percentUsed: Double
    let remainingBytes: Int
    let isAtLimit: Bool
}

struct SuccessResponse: Decodable {
    let success: Bool
}

struct RecalculateResponse: Decodable {
    let totalBytes: Int
    let mediaItemCount: Int
}

struct TripPermissionWithUser: Decodable {
    let id: String
    let userId: String
    let role: String
    let grantedVia: String
    let invitedBy: String
    let acceptedAt: Double
    let user: ConvexUserInfo?
}

struct ConvexUserInfo: Decodable {
    let name: String?
    let email: String?
    let imageUrl: String?
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
            storageId: storageId,
            thumbnailStorageId: thumbnailStorageId,
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
        let gridPos = GridPosition(
            column: Int(gridPosition.column),
            row: gridPosition.row,
            width: Int(gridPosition.width),
            height: gridPosition.height
        )

        return Moment(
            id: UUID(uuidString: momentId) ?? UUID(),
            title: title,
            note: note,
            mediaItemIDs: mediaItemIDs.compactMap { UUID(uuidString: $0) },
            timestamp: Date(timeIntervalSince1970: timestamp / 1000),
            date: date.map { Date(timeIntervalSince1970: $0 / 1000) },
            placeName: placeName,
            voiceNoteURL: voiceNoteURL,
            gridPosition: gridPos
        )
    }
}
