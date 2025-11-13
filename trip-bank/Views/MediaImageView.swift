import SwiftUI

// View that displays either a local image, Convex storage image, or remote URL
struct MediaImageView: View {
    let mediaItem: MediaItem
    @State private var imageURL: URL?
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let url = imageURL {
                // Load from URL (Convex storage or external)
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.1)
                            ProgressView()
                                .tint(.white)
                        }
                    case .success(let image):
                        image
                            .resizable()
                    case .failure(let error):
                        ZStack {
                            placeholderImage
                            VStack {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundStyle(.gray.opacity(0.5))
                            }
                        }
                        .onAppear {
                            print("Failed to load image: \(url)")
                            print("Error: \(error)")
                        }
                    @unknown default:
                        placeholderImage
                    }
                }
            } else if isLoading {
                ZStack {
                    Color.gray.opacity(0.1)
                    ProgressView()
                        .tint(.white)
                }
            } else if !mediaItem.imageName.isEmpty,
                      let image = ImageManager.shared.getImage(named: mediaItem.imageName) {
                // Fallback: Load from legacy local storage
                Image(uiImage: image)
                    .resizable()
            } else {
                placeholderImage
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        // Check if we already have a URL
        if let existingURL = mediaItem.imageURL {
            imageURL = existingURL
            return
        }

        // Try to load from Convex storage
        guard let storageId = mediaItem.storageId, !storageId.isEmpty else {
            return
        }

        isLoading = true

        do {
            let urlString = try await ConvexClient.shared.getFileUrl(storageId: storageId)
            if let url = URL(string: urlString) {
                imageURL = url
            } else {
                loadFailed = true
            }
        } catch {
            print("❌ Failed to load image URL from Convex: \(error)")
            loadFailed = true
        }

        isLoading = false
    }

    private var placeholderImage: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .gray.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}
