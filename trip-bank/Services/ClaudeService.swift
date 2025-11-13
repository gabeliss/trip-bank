import Foundation
import UIKit

// Placeholder for future AI-powered features
// This service will be used to auto-organize photos into moments,
// generate titles, and suggest moment importance levels
@MainActor
class ClaudeService {
    private let apiKey: String
    private let apiURL = "https://api.anthropic.com/v1/messages"
    private let model = "claude-3-5-sonnet-20241022"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Future AI Features
    // - Auto-generate moment titles from photos
    // - Suggest importance levels based on content
    // - Create trip narratives
    // - Auto-group photos into moments
}

// MARK: - Supporting Types

struct ImageContent {
    let mediaType: String
    let base64Data: String
}

enum ClaudeError: LocalizedError {
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case imageEncodingFailed
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Claude API"
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .imageEncodingFailed:
            return "Failed to encode image"
        case .invalidJSON:
            return "Failed to parse Claude response as JSON"
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let scale: CGFloat
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }

        if scale >= 1 {
            return self
        }

        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
