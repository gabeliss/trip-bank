import SwiftUI
import PhotosUI

// View for creating a new moment from selected media
struct CreateMomentView: View {
    let trip: Trip
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var note = ""
    @State private var placeName = ""
    @State private var eventName = ""
    @State private var date = Date()
    @State private var importance: MomentImportance = .medium
    @State private var selectedMediaItems: Set<UUID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Moment Details") {
                    TextField("Title (e.g., Sunset at the beach)", text: $title)
                    TextField("Place name", text: $placeName)
                    TextField("Event name (optional)", text: $eventName)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Description") {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                }

                Section("Importance") {
                    Picker("How important is this moment?", selection: $importance) {
                        Text("Small detail").tag(MomentImportance.small)
                        Text("Regular moment").tag(MomentImportance.medium)
                        Text("Highlight").tag(MomentImportance.large)
                        Text("Hero moment").tag(MomentImportance.hero)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Photos & Videos") {
                    if trip.mediaItems.isEmpty {
                        Text("No media available. Add photos first.")
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(trip.mediaItems) { mediaItem in
                                    MediaThumbnailView(
                                        mediaItem: mediaItem,
                                        isSelected: selectedMediaItems.contains(mediaItem.id),
                                        onTap: {
                                            if selectedMediaItems.contains(mediaItem.id) {
                                                selectedMediaItems.remove(mediaItem.id)
                                            } else {
                                                selectedMediaItems.insert(mediaItem.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createMoment()
                    }
                    .disabled(title.isEmpty || selectedMediaItems.isEmpty)
                }
            }
        }
    }

    private func createMoment() {
        let moment = Moment(
            title: title,
            note: note.isEmpty ? nil : note,
            mediaItemIDs: Array(selectedMediaItems),
            date: date,
            placeName: placeName.isEmpty ? nil : placeName,
            eventName: eventName.isEmpty ? nil : eventName,
            importance: importance
        )

        tripStore.addMoment(to: trip.id, moment: moment)
        dismiss()
    }
}

// Thumbnail view for selecting media items
struct MediaThumbnailView: View {
    let mediaItem: MediaItem
    let isSelected: Bool
    let onTap: () -> Void

    @State private var imageURL: URL?
    @State private var isLoading = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Image content
            Group {
                if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                Color.gray.opacity(0.2)
                                ProgressView()
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "photo")
                                    .foregroundStyle(.gray)
                            }
                        @unknown default:
                            Color.gray.opacity(0.2)
                        }
                    }
                } else if let existingURL = mediaItem.imageURL {
                    AsyncImage(url: existingURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            Color.gray.opacity(0.2)
                        }
                    }
                } else if !mediaItem.imageName.isEmpty,
                          let image = ImageManager.shared.getImage(named: mediaItem.imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else if isLoading {
                    ZStack {
                        Color.gray.opacity(0.2)
                        ProgressView()
                    }
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            }

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                    .background(Circle().fill(.white))
                    .padding(4)
            }
        }
        .onTapGesture {
            onTap()
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        // Skip if we already have a URL
        if mediaItem.imageURL != nil {
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
            }
        } catch {
            print("❌ Failed to load thumbnail URL from Convex: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    CreateMomentView(trip: Trip(title: "Test Trip"))
        .environmentObject(TripStore())
}
