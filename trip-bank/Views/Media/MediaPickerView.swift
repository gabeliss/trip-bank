import SwiftUI

enum MediaPickerState {
    case selectingFromLibrary
    case loadingMedia(current: Int, total: Int)
    case previewing([SelectedMediaItem])
    case uploading(current: Int, total: Int)
    case error(String)
    case storageLimitReached(String)
    case storageLimitWarning(media: [SelectedMediaItem], canFit: Int, totalSize: Int64, remainingBytes: Int64)
}

struct MediaPickerView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    @State private var state: MediaPickerState = .selectingFromLibrary
    @State private var showingSubscriptionView = false

    var body: some View {
        Group {
            switch state {
            case .selectingFromLibrary:
                PHPickerView { result in
                    handlePickerResult(result)
                }

            case .loadingMedia(let current, let total):
                NavigationStack {
                    VStack(spacing: 16) {
                        ProgressView(value: Double(current), total: Double(total))
                            .padding(.horizontal, 40)
                        Text("Loading \(current)/\(total)...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .navigationTitle("Add Media")
                    .navigationBarTitleDisplayMode(.inline)
                }

            case .previewing(let media):
                NavigationStack {
                    PreviewView(media: media) {
                        Task {
                            await uploadMedia(media)
                        }
                    } onSelectDifferent: {
                        state = .selectingFromLibrary
                    } onRemove: { index in
                        removeItem(at: index, from: media)
                    }
                    .background(Color(.systemBackground))
                    .navigationTitle("Add Media")
                    .navigationBarTitleDisplayMode(.inline)
                }

            case .uploading(let current, let total):
                NavigationStack {
                    VStack(spacing: 16) {
                        ProgressView(value: Double(current), total: Double(total))
                            .padding(.horizontal)
                        Text("Uploading \(current)/\(total)...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .navigationTitle("Add Media")
                    .navigationBarTitleDisplayMode(.inline)
                }

            case .error(let message):
                NavigationStack {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundStyle(.red)
                        Text("Upload Failed")
                            .font(.headline)
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            state = .selectingFromLibrary
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .navigationTitle("Add Media")
                    .navigationBarTitleDisplayMode(.inline)
                }

            case .storageLimitReached(let message):
                NavigationStack {
                    VStack(spacing: 20) {
                        Image(systemName: "externaldrive.badge.xmark")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)

                        Text("Storage Limit Reached")
                            .font(.headline)

                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if subscriptionManager.currentTier == .free {
                            Button {
                                showingSubscriptionView = true
                            } label: {
                                HStack {
                                    Image(systemName: "crown.fill")
                                    Text("Upgrade to Pro")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 40)
                        }

                        Button("Go Back") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .navigationTitle("Add Media")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .sheet(isPresented: $showingSubscriptionView) {
                    SubscriptionView()
                }

            case .storageLimitWarning(let media, let canFit, let totalSize, let remainingBytes):
                NavigationStack {
                    VStack(spacing: 20) {
                        Image(systemName: "externaldrive.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)

                        Text("Not Enough Storage")
                            .font(.headline)

                        Text("You selected \(media.count) items (\(formatBytes(totalSize))), but you only have \(formatBytes(remainingBytes)) remaining.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if canFit > 0 {
                            VStack(spacing: 12) {
                                Button {
                                    let itemsToUpload = Array(media.prefix(canFit))
                                    Task {
                                        await uploadMedia(itemsToUpload)
                                    }
                                } label: {
                                    Text("Upload First \(canFit) Items")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .padding(.horizontal, 40)
                            }
                        }

                        if subscriptionManager.currentTier == .free {
                            Button {
                                showingSubscriptionView = true
                            } label: {
                                HStack {
                                    Image(systemName: "crown.fill")
                                    Text("Upgrade to Pro")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 40)
                        }

                        Button("Select Different Items") {
                            state = .selectingFromLibrary
                        }
                        .buttonStyle(.bordered)

                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .navigationTitle("Add Media")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .sheet(isPresented: $showingSubscriptionView) {
                    SubscriptionView()
                }
            }
        }
        .task {
            // Refresh storage usage when view appears
            await subscriptionManager.fetchStorageUsage()
        }
    }

    private func handlePickerResult(_ result: MediaPickerResult) {
        switch result {
        case .cancelled:
            dismiss()

        case .loading(let current, let total):
            state = .loadingMedia(current: current, total: total)

        case .loaded(let media):
            state = .previewing(media)
        }
    }

    private func removeItem(at index: Int, from media: [SelectedMediaItem]) {
        var updatedMedia = media
        updatedMedia.remove(at: index)

        if updatedMedia.isEmpty {
            // If all items removed, go back to selection
            state = .selectingFromLibrary
        } else {
            // Update preview with remaining items
            state = .previewing(updatedMedia)
        }
    }

    /// Estimate the file size of a media item before upload
    private func estimateSize(of item: SelectedMediaItem) -> Int64 {
        if item.isVideo, let videoURL = item.videoURL {
            // Get actual file size for videos
            if let attrs = try? FileManager.default.attributesOfItem(atPath: videoURL.path),
               let fileSize = attrs[.size] as? Int64 {
                return fileSize
            }
            return 10 * 1024 * 1024 // Default 10MB estimate for videos
        } else if let image = item.image {
            // Estimate JPEG size (images are compressed when uploaded)
            // Using 0.8 compression quality as a rough estimate
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                return Int64(jpegData.count)
            }
            return 2 * 1024 * 1024 // Default 2MB estimate for images
        }
        return 1 * 1024 * 1024 // Default 1MB
    }

    /// Calculate how many items can fit in the remaining storage
    private func calculateItemsThatFit(_ media: [SelectedMediaItem], remainingBytes: Int64) -> (canFit: Int, totalSize: Int64, sizes: [Int64]) {
        var sizes: [Int64] = []
        var totalSize: Int64 = 0
        var canFit = 0
        var runningTotal: Int64 = 0

        for item in media {
            let size = estimateSize(of: item)
            sizes.append(size)
            totalSize += size

            if runningTotal + size <= remainingBytes {
                runningTotal += size
                canFit += 1
            }
        }

        return (canFit, totalSize, sizes)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func uploadMedia(_ media: [SelectedMediaItem]) async {
        let convexClient = ConvexClient.shared
        var newMediaItems: [MediaItem] = []

        // Refresh storage usage before upload
        await subscriptionManager.fetchStorageUsage()

        // Check if user is at storage limit before starting
        if let usage = subscriptionManager.storageUsage, usage.isAtLimit {
            state = .storageLimitReached("You've used all \(usage.limitFormatted) of your storage. Delete some media or upgrade to continue.")
            return
        }

        // Check if all selected items will fit
        if let usage = subscriptionManager.storageUsage {
            let (canFit, totalSize, _) = calculateItemsThatFit(media, remainingBytes: usage.remainingBytes)

            if canFit < media.count {
                // Not all items will fit - show warning with options
                state = .storageLimitWarning(
                    media: media,
                    canFit: canFit,
                    totalSize: totalSize,
                    remainingBytes: usage.remainingBytes
                )
                return
            }
        }

        for (index, item) in media.enumerated() {
            state = .uploading(current: index + 1, total: media.count)

            do {
                var fileSize: Int = 0
                var thumbnailSize: Int = 0
                let storageId: String
                let thumbnailStorageId: String?
                let mediaType: MediaType

                if item.isVideo, let videoURL = item.videoURL {
                    // Upload the video file
                    let videoResult = try await convexClient.uploadVideoWithSize(videoURL)
                    storageId = videoResult.storageId
                    fileSize = videoResult.fileSize

                    // Upload the thumbnail image if available
                    if let thumbnail = item.image {
                        let thumbResult = try await convexClient.uploadImageWithSize(thumbnail)
                        thumbnailStorageId = thumbResult.storageId
                        thumbnailSize = thumbResult.fileSize
                    } else {
                        thumbnailStorageId = nil
                    }

                    mediaType = .video
                } else if let image = item.image {
                    let imageResult = try await convexClient.uploadImageWithSize(image)
                    storageId = imageResult.storageId
                    fileSize = imageResult.fileSize
                    thumbnailStorageId = nil
                    mediaType = .photo
                } else {
                    continue
                }

                newMediaItems.append(MediaItem(
                    storageId: storageId,
                    thumbnailStorageId: thumbnailStorageId,
                    type: mediaType,
                    captureDate: Date(),
                    fileSize: fileSize,
                    thumbnailSize: thumbnailSize > 0 ? thumbnailSize : nil
                ))
            } catch let error as ConvexError {
                // Check if it's a storage limit error from backend
                if case .convexError(let message) = error, message.contains("Storage limit") {
                    state = .storageLimitReached(message)
                } else {
                    state = .error(error.localizedDescription)
                }
                return
            } catch {
                state = .error(error.localizedDescription)
                return
            }
        }

        if !newMediaItems.isEmpty {
            tripStore.addMediaItems(to: trip.id, mediaItems: newMediaItems)
        }

        // Refresh storage usage after upload
        await subscriptionManager.fetchStorageUsage()

        dismiss()
    }
}

// Preview subview
struct PreviewView: View {
    let media: [SelectedMediaItem]
    let onUpload: () -> Void
    let onSelectDifferent: () -> Void
    let onRemove: (Int) -> Void

    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 12)
                ], spacing: 12) {
                    ForEach(media.indices, id: \.self) { index in
                        ZStack {
                            if let image = media[index].image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            // Video play icon (bottom-trailing)
                            if media[index].isVideo {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .foregroundStyle(.white)
                                            .font(.title2)
                                            .shadow(radius: 2)
                                            .padding(4)
                                    }
                                }
                            }

                            // Remove button (top-trailing)
                            VStack {
                                HStack {
                                    Spacer()
                                    Button {
                                        onRemove(index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.white, .red)
                                            .font(.title3)
                                            .shadow(radius: 2)
                                    }
                                    .padding(4)
                                }
                                Spacer()
                            }
                        }
                        .frame(width: 100, height: 100)
                    }
                }
                .padding()
            }

            VStack(spacing: 12) {
                Button("Add \(media.count) to Trip") {
                    onUpload()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Select Different Items") {
                    onSelectDifferent()
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MediaPickerView(trip: Trip(title: "Test Trip"))
        .environmentObject(TripStore())
}
