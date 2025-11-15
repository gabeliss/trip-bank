import SwiftUI

// View for managing (editing/deleting) media items in a trip
struct ManageMediaView: View {
    let trip: Trip
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedMediaItem: MediaItem?
    @State private var showingDeleteConfirmation = false

    // Get the latest version of the trip from the store
    private var currentTrip: Trip {
        tripStore.trips.first(where: { $0.id == trip.id }) ?? trip
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if currentTrip.mediaItems.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 100), spacing: 12)
                    ], spacing: 12) {
                        ForEach(currentTrip.mediaItems) { mediaItem in
                            MediaItemTile(
                                mediaItem: mediaItem,
                                onDelete: {
                                    selectedMediaItem = mediaItem
                                    showingDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Manage Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Photo?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteSelectedMedia()
                }
            } message: {
                Text("This photo will be removed from all moments and permanently deleted.")
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
            Text("Add photos to your trip to see them here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func deleteSelectedMedia() {
        guard let mediaItem = selectedMediaItem else { return }
        tripStore.deleteMediaItem(from: trip.id, mediaItemID: mediaItem.id)
    }
}

// Tile view for a media item in the grid
struct MediaItemTile: View {
    let mediaItem: MediaItem
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            MediaImageView(mediaItem: mediaItem)
                .id(mediaItem.id)
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Delete button (top-right corner)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDelete()
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

#Preview {
    ManageMediaView(trip: Trip(title: "Test Trip"))
        .environmentObject(TripStore())
}
