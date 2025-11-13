import Foundation

// Placeholder for future AI-powered features
// Could be used to:
// - Auto-generate moment titles and descriptions
// - Suggest moment importance levels
// - Auto-organize photos into moments
// - Generate trip narratives

struct AIMetadata: Codable {
    var generatedNarrative: String?
    var suggestedTitle: String?
    var generatedAt: Date

    init(generatedNarrative: String? = nil,
         suggestedTitle: String? = nil,
         generatedAt: Date = Date()) {
        self.generatedNarrative = generatedNarrative
        self.suggestedTitle = suggestedTitle
        self.generatedAt = generatedAt
    }
}
