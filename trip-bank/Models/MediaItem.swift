import Foundation
import UIKit

enum MediaType: String, Codable {
    case photo
    case video
}

struct MediaItem: Identifiable, Codable {
    let id: UUID
    var storageId: String? // Convex storage ID (for photos or videos)
    var thumbnailStorageId: String? // Convex storage ID for video thumbnail
    var imageURL: URL? // For remote images (e.g., Unsplash)
    var videoURL: URL? // For video files
    var type: MediaType
    var captureDate: Date?
    var note: String?
    var timestamp: Date // When added to the trip
    var fileSize: Int? // Size in bytes of main file
    var thumbnailSize: Int? // Size in bytes of thumbnail (for videos)

    init(id: UUID = UUID(),
         storageId: String? = nil,
         thumbnailStorageId: String? = nil,
         imageURL: URL? = nil,
         videoURL: URL? = nil,
         type: MediaType = .photo,
         captureDate: Date? = nil,
         note: String? = nil,
         timestamp: Date = Date(),
         fileSize: Int? = nil,
         thumbnailSize: Int? = nil) {
        self.id = id
        self.storageId = storageId
        self.thumbnailStorageId = thumbnailStorageId
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.type = type
        self.captureDate = captureDate
        self.note = note
        self.timestamp = timestamp
        self.fileSize = fileSize
        self.thumbnailSize = thumbnailSize
    }

    var displayDate: String? {
        guard let date = captureDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
