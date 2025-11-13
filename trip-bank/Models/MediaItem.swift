import Foundation
import UIKit

enum MediaType: String, Codable {
    case photo
    case video
}

struct MediaItem: Identifiable, Codable {
    let id: UUID
    var imageName: String // Reference to stored image/video thumbnail (legacy)
    var storageId: String? // Convex storage ID
    var imageURL: URL? // For remote images (e.g., Unsplash)
    var videoURL: URL? // For video files
    var type: MediaType
    var captureDate: Date?
    var note: String?
    var timestamp: Date // When added to the trip

    init(id: UUID = UUID(),
         imageName: String = "",
         storageId: String? = nil,
         imageURL: URL? = nil,
         videoURL: URL? = nil,
         type: MediaType = .photo,
         captureDate: Date? = nil,
         note: String? = nil,
         timestamp: Date = Date()) {
        self.id = id
        self.imageName = imageName
        self.storageId = storageId
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.type = type
        self.captureDate = captureDate
        self.note = note
        self.timestamp = timestamp
    }

    var displayDate: String? {
        guard let date = captureDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
