import SwiftUI
import UIKit

extension UIView {
    /// Captures a screenshot of the view
    @MainActor
    func asImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { context in
            layer.render(in: context.cgContext)
        }
    }
}

extension View {
    /// Captures a snapshot of the current view as rendered on screen
    @MainActor
    func snapshot() -> UIImage? {
        // Get the key window
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            print("❌ Could not find key window")
            return nil
        }

        // Capture the entire window
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
    }
}

struct ViewCapturePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct CanvasSnapshotGenerator {
    /// Capture the currently rendered canvas view from the screen
    @MainActor
    static func captureCurrentView() -> UIImage? {
        print("📸 Capturing current view from screen...")

        // Debug: Print all connected scenes
        let scenes = UIApplication.shared.connectedScenes
        print("   - Connected scenes count: \(scenes.count)")

        let windowScenes = scenes.compactMap({ $0 as? UIWindowScene })
        print("   - Window scenes count: \(windowScenes.count)")

        let allWindows = windowScenes.flatMap({ $0.windows })
        print("   - All windows count: \(allWindows.count)")

        // Get the key window
        guard let window = allWindows.first(where: { $0.isKeyWindow }) else {
            print("❌ Could not find key window")
            print("   - Available windows: \(allWindows.map { "isKey: \($0.isKeyWindow), bounds: \($0.bounds)" })")
            return nil
        }

        print("   - Found key window with bounds: \(window.bounds)")

        // Capture the entire window
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }

        print("✅ Captured image: \(image.size.width) x \(image.size.height)")
        return image
    }

    /// Create a simple placeholder image when moments aren't available
    @MainActor
    static func createPlaceholderImage(for trip: Trip, size: CGSize = CGSize(width: 1200, height: 800)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw trip title
            let title = trip.title as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.systemBlue
            ]
            let titleSize = title.size(withAttributes: attributes)
            let titleRect = CGRect(
                x: (size.width - titleSize.width) / 2,
                y: (size.height - titleSize.height) / 2,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: attributes)
        }
    }

    /// Convert UIImage to JPEG data for upload
    static func imageToJPEG(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: compressionQuality)
    }
}
