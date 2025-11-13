import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @EnvironmentObject var tripStore: TripStore
    @State private var showingMediaPicker = false
    @State private var showingCreateMoment = false

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
                TripCanvasView(trip: currentTrip)
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
        }
        .sheet(isPresented: $showingMediaPicker) {
            MediaPickerView(trip: trip)
        }
        .sheet(isPresented: $showingCreateMoment) {
            CreateMomentView(trip: currentTrip)
        }
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

#Preview {
    NavigationStack {
        TripDetailView(trip: Trip(title: "Portugal Adventure"))
            .environmentObject(TripStore())
    }
}
