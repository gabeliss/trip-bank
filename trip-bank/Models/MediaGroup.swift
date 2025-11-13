import Foundation

// Moment represents a collection of photos/videos from a specific experience
// e.g., "Hiking to the waterfall", "Sunset at the beach", "Dinner in Lisbon"
struct Moment: Identifiable, Codable {
    let id: UUID
    var title: String
    var note: String? // Text description
    var mediaItemIDs: [UUID] // References to MediaItem IDs
    var timestamp: Date

    // Enhanced metadata from prompt requirements
    var date: Date? // When this moment happened
    var placeName: String? // "Golden Gate Bridge", "Louvre Museum"
    var eventName: String? // "Birthday celebration", "Wedding ceremony"
    var voiceNoteURL: String? // Path to audio file (future feature)

    // Visual layout properties for spatial canvas
    var importance: MomentImportance // Determines size on canvas
    var layoutPosition: CGPoint? // Position on canvas (auto-generated or manual)
    var layoutSize: MomentSize? // Size category (auto-generated or manual)

    init(id: UUID = UUID(),
         title: String,
         note: String? = nil,
         mediaItemIDs: [UUID] = [],
         timestamp: Date = Date(),
         date: Date? = nil,
         placeName: String? = nil,
         eventName: String? = nil,
         voiceNoteURL: String? = nil,
         importance: MomentImportance = .medium,
         layoutPosition: CGPoint? = nil,
         layoutSize: MomentSize? = nil) {
        self.id = id
        self.title = title
        self.note = note
        self.mediaItemIDs = mediaItemIDs
        self.timestamp = timestamp
        self.date = date
        self.placeName = placeName
        self.eventName = eventName
        self.voiceNoteURL = voiceNoteURL
        self.importance = importance
        self.layoutPosition = layoutPosition
        self.layoutSize = layoutSize
    }
}

// Importance level affects size on the spatial canvas
enum MomentImportance: String, Codable {
    case small // Minor moments, takes less space
    case medium // Regular moments
    case large // Important highlights, takes more space
    case hero // Key moments of the trip, largest size
}

// Pre-defined size categories for moments on canvas
enum MomentSize: String, Codable {
    case compact // ~150x150 pts
    case regular // ~200x200 pts
    case large // ~300x200 pts
    case hero // ~350x300 pts
    case wide // ~350x180 pts (panoramic)
    case tall // ~180x300 pts (portrait)
}
