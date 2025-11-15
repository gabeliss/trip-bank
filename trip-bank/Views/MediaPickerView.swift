import SwiftUI

enum MediaPickerState {
    case selectingFromLibrary
    case loadingMedia(count: Int)
    case previewing([SelectedMediaItem])
    case uploading(current: Int, total: Int)
    case error(String)
}

struct MediaPickerView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore

    @State private var state: MediaPickerState = .selectingFromLibrary

    var body: some View {
        NavigationStack {
            VStack {
                switch state {
                case .selectingFromLibrary:
                    PHPickerView { result in
                        handlePickerResult(result)
                    }

                case .loadingMedia(let count):
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading \(count) item(s)...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .previewing(let media):
                    PreviewView(media: media) {
                        Task {
                            await uploadMedia(media)
                        }
                    } onSelectDifferent: {
                        state = .selectingFromLibrary
                    } onRemove: { index in
                        removeItem(at: index, from: media)
                    }

                case .uploading(let current, let total):
                    VStack(spacing: 16) {
                        ProgressView(value: Double(current), total: Double(total))
                            .padding(.horizontal)
                        Text("Uploading \(current)/\(total)...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .error(let message):
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
                }
            }
            .navigationTitle("Add Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func handlePickerResult(_ result: MediaPickerResult) {
        switch result {
        case .cancelled:
            dismiss()

        case .loading(let count):
            state = .loadingMedia(count: count)

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

    private func uploadMedia(_ media: [SelectedMediaItem]) async {
        let convexClient = ConvexClient.shared
        var newMediaItems: [MediaItem] = []

        for (index, item) in media.enumerated() {
            state = .uploading(current: index, total: media.count)

            do {
                let storageId: String
                let mediaType: MediaType

                if item.isVideo, let videoURL = item.videoURL {
                    storageId = try await convexClient.uploadVideo(videoURL)
                    mediaType = .video
                } else if let image = item.image {
                    storageId = try await convexClient.uploadImage(image)
                    mediaType = .photo
                } else {
                    continue
                }

                newMediaItems.append(MediaItem(
                    storageId: storageId,
                    type: mediaType,
                    captureDate: Date()
                ))
            } catch {
                state = .error(error.localizedDescription)
                return
            }
        }

        if !newMediaItems.isEmpty {
            tripStore.addMediaItems(to: trip.id, mediaItems: newMediaItems)
        }

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
        VStack(spacing: 16) {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MediaPickerView(trip: Trip(title: "Test Trip"))
        .environmentObject(TripStore())
}
