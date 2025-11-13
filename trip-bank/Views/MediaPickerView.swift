import SwiftUI
import PhotosUI

struct MediaPickerView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0

    var body: some View {
        NavigationStack {
            VStack {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .any(of: [.images, .videos])
                ) {
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)

                        Text("Select Photos & Videos")
                            .font(.headline)

                        Text("Choose up to 10 items")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onChange(of: selectedItems) { oldValue, newValue in
                    Task {
                        await loadImages()
                    }
                }

                if !selectedImages.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(selectedImages.indices, id: \.self) { index in
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding()
                    }

                    if isUploading {
                        VStack(spacing: 8) {
                            ProgressView(value: uploadProgress, total: Double(selectedImages.count))
                                .padding(.horizontal)
                            Text("Uploading \(Int(uploadProgress)) of \(selectedImages.count) images...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else {
                        Button("Add to Trip") {
                            Task {
                                await addMediaToTrip()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
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

    private func loadImages() async {
        selectedImages = []

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }

    private func addMediaToTrip() async {
        isUploading = true
        uploadProgress = 0

        let convexClient = ConvexClient.shared
        var newMediaItems: [MediaItem] = []

        for (index, image) in selectedImages.enumerated() {
            do {
                // Upload image to Convex storage
                let storageId = try await convexClient.uploadImage(image)

                // Create MediaItem with storage ID
                let mediaItem = MediaItem(
                    storageId: storageId,
                    type: .photo,
                    captureDate: Date()
                )

                newMediaItems.append(mediaItem)

                // Update progress
                uploadProgress = Double(index + 1)
            } catch {
                print("❌ Failed to upload image: \(error)")
                // Continue with other images even if one fails
            }
        }

        // Add to trip
        tripStore.addMediaItems(to: trip.id, mediaItems: newMediaItems)

        isUploading = false
        dismiss()
    }
}

#Preview {
    MediaPickerView(trip: Trip(title: "Test Trip"))
        .environmentObject(TripStore())
}
