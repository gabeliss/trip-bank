import SwiftUI

struct NewTripView: View {
    let trip: Trip? // Optional: if provided, we're editing
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isCreating = false
    @State private var showError = false
    @State private var selectedCoverImageStorageId: String?
    @State private var showingCoverImagePicker = false

    private var isEditing: Bool {
        trip != nil
    }

    // Get the latest version of the trip from the store (for media items)
    private var currentTrip: Trip {
        tripStore.trips.first(where: { $0.id == trip?.id }) ?? trip ?? Trip(title: "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Trip Name", text: $title)
                } header: {
                    Text("Trip Details")
                }

                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                } header: {
                    Text("Dates")
                }

                // Cover Image section (only when editing and trip has media items)
                if isEditing && !currentTrip.mediaItems.isEmpty {
                    Section {
                        Button {
                            showingCoverImagePicker = true
                        } label: {
                            HStack {
                                Text("Cover Image")
                                    .foregroundStyle(.primary)

                                Spacer()

                                if let storageId = selectedCoverImageStorageId,
                                   let mediaItem = currentTrip.mediaItems.first(where: { $0.storageId == storageId }) {
                                    MediaImageView(mediaItem: mediaItem)
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    Image(systemName: "photo")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 60, height: 60)
                                }

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }

                if isCreating {
                    Section {
                        HStack {
                            ProgressView()
                            Text(isEditing ? "Saving..." : "Creating trip...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Trip" : "New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let trip = trip {
                    title = trip.title
                    startDate = trip.startDate
                    endDate = trip.endDate
                    selectedCoverImageStorageId = trip.coverImageStorageId
                }
            }
            .sheet(isPresented: $showingCoverImagePicker) {
                CoverImagePicker(
                    mediaItems: currentTrip.mediaItems,
                    selectedStorageId: $selectedCoverImageStorageId
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isCreating)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        if isEditing {
                            updateTrip()
                        } else {
                            createTrip()
                        }
                    }
                    .disabled(title.isEmpty || isCreating)
                }
            }
            .alert("Error Creating Trip", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    showError = false
                }
            } message: {
                if let errorMessage = tripStore.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    private func createTrip() {
        isCreating = true

        let newTrip = Trip(
            title: title,
            startDate: startDate,
            endDate: endDate
        )

        tripStore.addTrip(newTrip)

        // Give a brief moment for the backend call to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCreating = false

            if tripStore.errorMessage != nil {
                showError = true
            } else {
                dismiss()
            }
        }
    }

    private func updateTrip() {
        guard let existingTrip = trip else { return }
        isCreating = true

        var updatedTrip = existingTrip
        updatedTrip.title = title
        updatedTrip.startDate = startDate
        updatedTrip.endDate = endDate
        updatedTrip.coverImageStorageId = selectedCoverImageStorageId
        // Update coverImageName to match the selected media item
        if let storageId = selectedCoverImageStorageId,
           let mediaItem = currentTrip.mediaItems.first(where: { $0.storageId == storageId }) {
            updatedTrip.coverImageName = mediaItem.id.uuidString
        }

        tripStore.updateTrip(updatedTrip)

        // Give a brief moment for the backend call to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCreating = false

            if tripStore.errorMessage != nil {
                showError = true
            } else {
                dismiss()
            }
        }
    }
}

#Preview {
    NewTripView(trip: nil)
        .environmentObject(TripStore())
}
