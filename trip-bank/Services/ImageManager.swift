import Foundation
import UIKit

@MainActor
class ImageManager: ObservableObject {
    static let shared = ImageManager()

    private var imageCache: [String: UIImage] = [:]

    private init() {}

    /// Save an image and return a unique identifier
    func saveImage(_ image: UIImage) -> String {
        let imageID = UUID().uuidString
        imageCache[imageID] = image
        return imageID
    }

    /// Retrieve an image by its identifier
    func getImage(named imageName: String) -> UIImage? {
        return imageCache[imageName]
    }

    /// Get all images for given image names
    func getImages(named imageNames: [String]) -> [UIImage] {
        return imageNames.compactMap { imageCache[$0] }
    }

    /// Delete an image
    func deleteImage(named imageName: String) {
        imageCache.removeValue(forKey: imageName)
    }

    /// Clear all cached images
    func clearAll() {
        imageCache.removeAll()
    }
}
