import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @EnvironmentObject var tripStore: TripStore
    @State private var showingMediaPicker = false
    @State private var showingCreateMoment = false
    @State private var showingEditTrip = false
    @State private var showingDeleteConfirmation = false
    @State private var showingManageMedia = false
    @Environment(\.dismiss) var dismiss

    // Get the latest version of the trip from the store
    private var currentTrip: Trip {
        tripStore.trips.first(where: { $0.id == trip.id }) ?? trip
    }

    var body: some View {
        ZStack {
            if currentTrip.moments.isEmpty {
                // Show empty state or getting started flow
                emptyMomentsState
            } else {
                // Show spatial canvas with moments
                TripCanvasView(tripId: trip.id)
            }
        }
        .navigationTitle(currentTrip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingMediaPicker = true
                    } label: {
                        Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                    }

                    if !currentTrip.mediaItems.isEmpty {
                        Button {
                            showingCreateMoment = true
                        } label: {
                            Label("Create Moment", systemImage: "sparkles")
                        }
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingManageMedia = true
                    } label: {
                        Label("Manage Photos", systemImage: "photo.stack")
                    }
                    .disabled(currentTrip.mediaItems.isEmpty)

                    Button {
                        showingEditTrip = true
                    } label: {
                        Label("Edit Trip", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Trip", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingMediaPicker) {
            MediaPickerView(trip: trip)
        }
        .sheet(isPresented: $showingCreateMoment) {
            CreateMomentView(trip: currentTrip, moment: nil)
        }
        .sheet(isPresented: $showingEditTrip) {
            NewTripView(trip: currentTrip)
        }
        .sheet(isPresented: $showingManageMedia) {
            ManageMediaView(trip: currentTrip)
        }
        .alert("Delete Trip?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("This will delete the trip and all its photos and moments. This action cannot be undone.")
        }
    }

    private func deleteTrip() {
        tripStore.deleteTrip(at: IndexSet(integer: tripStore.trips.firstIndex(where: { $0.id == trip.id }) ?? 0))
        dismiss()
    }

    private var emptyMomentsState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "map.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.opacity(0.6))

            VStack(spacing: 12) {
                Text("Start Your Story")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Add photos and organize them into moments to create a beautiful visual journey")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 16) {
                Button {
                    showingMediaPicker = true
                } label: {
                    Label("Add Photos & Videos", systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if !currentTrip.mediaItems.isEmpty {
                    Button {
                        showingCreateMoment = true
                    } label: {
                        Label("Create First Moment", systemImage: "sparkles")
                            .frame(maxWidth: 280)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Text("\(currentTrip.mediaItems.count) photos added")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 20)

            Spacer()
        }
    }
}
