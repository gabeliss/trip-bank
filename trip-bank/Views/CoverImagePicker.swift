import SwiftUI

// View for selecting a cover image from trip media items
struct CoverImagePicker: View {
    let mediaItems: [MediaItem]
    @Binding var selectedStorageId: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if mediaItems.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 12)
                    ], spacing: 12) {
                        ForEach(mediaItems) { mediaItem in
                            SelectableMediaTile(
                                mediaItem: mediaItem,
                                isSelected: mediaItem.storageId == selectedStorageId,
                                onSelect: {
                                    selectedStorageId = mediaItem.storageId
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Cover Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedStorageId == nil)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No Photos Yet")
                .font(.headline)
            Text("Add photos to your trip to select a cover image")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// Selectable tile view for a media item (no play button for videos, no delete button)
struct SelectableMediaTile: View {
    let mediaItem: MediaItem
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            ZStack {
                MediaImageView(mediaItem: mediaItem)
                    .id(mediaItem.id)
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    }

                // Selection indicator
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white, .blue)
                                .font(.title3)
                                .shadow(radius: 2)
                                .padding(4)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 100, height: 100)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CoverImagePicker(
        mediaItems: [],
        selectedStorageId: .constant(nil)
    )
}
