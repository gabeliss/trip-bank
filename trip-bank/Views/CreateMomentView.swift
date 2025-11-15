import SwiftUI
import PhotosUI

// View for creating or editing a moment
struct CreateMomentView: View {
    let trip: Trip
    let moment: Moment? // Optional: if provided, we're editing
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var note = ""
    @State private var placeName = ""
    @State private var eventName = ""
    @State private var date = Date()
    @State private var momentWidth: Double = 1
    @State private var momentHeight: Double = 1.5
    @State private var selectedMediaItems: Set<UUID> = []

    private var isEditing: Bool {
        moment != nil
    }

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

                Section {
                    MomentSizePicker(width: $momentWidth, height: $momentHeight)
                        .padding(.vertical, 8)
                } header: {
                    Text("Size")
                } footer: {
                    Text("You can resize this later by double-tapping the moment")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Photos & Videos") {
                    if trip.mediaItems.isEmpty {
                        Text("No media available. Add photos first.")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
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
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Moment" : "Create Moment")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let moment = moment {
                    title = moment.title
                    note = moment.note ?? ""
                    placeName = moment.placeName ?? ""
                    eventName = moment.eventName ?? ""
                    date = moment.date ?? Date()
                    momentWidth = Double(moment.gridPosition.width)
                    momentHeight = moment.gridPosition.height
                    selectedMediaItems = Set(moment.mediaItemIDs)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        if isEditing {
                            updateMoment()
                        } else {
                            createMoment()
                        }
                    }
                    .disabled(title.isEmpty || selectedMediaItems.isEmpty)
                }
            }
        }
    }

    private func createMoment() {
        // Calculate grid position for new moment using selected size
        let desiredSize = GridPosition(
            column: 0,
            row: 0,
            width: Int(momentWidth),
            height: momentHeight
        )
        let gridPosition = GridLayoutCalculator.calculateNextGridPosition(
            existingMoments: trip.moments,
            momentSize: desiredSize
        )

        let newMoment = Moment(
            title: title,
            note: note.isEmpty ? nil : note,
            mediaItemIDs: Array(selectedMediaItems),
            date: date,
            placeName: placeName.isEmpty ? nil : placeName,
            eventName: eventName.isEmpty ? nil : eventName,
            gridPosition: gridPosition
        )

        tripStore.addMoment(to: trip.id, moment: newMoment)
        dismiss()
    }

    private func updateMoment() {
        guard let existingMoment = moment else { return }

        var updatedMoment = existingMoment
        updatedMoment.title = title
        updatedMoment.note = note.isEmpty ? nil : note
        updatedMoment.mediaItemIDs = Array(selectedMediaItems)
        updatedMoment.date = date
        updatedMoment.placeName = placeName.isEmpty ? nil : placeName
        updatedMoment.eventName = eventName.isEmpty ? nil : eventName

        // Update grid position size
        updatedMoment.gridPosition.width = Int(momentWidth)
        updatedMoment.gridPosition.height = momentHeight

        tripStore.updateMoment(in: trip.id, moment: updatedMoment)
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

            // Check if task was cancelled
            try Task.checkCancellation()

            if let url = URL(string: urlString) {
                imageURL = url
            }
        } catch is CancellationError {
            // Task was cancelled, this is normal - don't log error
            return
        } catch {
            // Only log non-cancellation errors
            print("❌ Failed to load thumbnail URL from Convex: \(error)")
        }

        isLoading = false
    }
}

#Preview {
    CreateMomentView(trip: Trip(title: "Test Trip"), moment: nil)
        .environmentObject(TripStore())
}
