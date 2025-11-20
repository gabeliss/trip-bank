import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @EnvironmentObject var tripStore: TripStore
    @State private var showingMediaPicker = false
    @State private var showingCreateMoment = false
    @State private var showingEditTrip = false
    @State private var showingDeleteConfirmation = false
    @State private var showingManageMedia = false
    @State private var showingShareTrip = false
    @State private var showingManageAccess = false
    @Environment(\.dismiss) var dismiss

    // Permissions
    @State private var canEdit = false
    @State private var canDelete = false
    @State private var canManageAccess = false
    @State private var permissions: [TripPermissionWithUser] = []

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
            // Show collaborator avatars if there are multiple people
            if permissions.count > 1 {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text(currentTrip.title)
                            .fontWeight(.semibold)

                        Spacer().frame(width: 8)

                        collaboratorAvatars
                    }
                }
            }
        }
        .onAppear {
            // Check permissions when view appears
            canEdit = tripStore.canEdit(trip: currentTrip)
            canDelete = tripStore.isOwner(trip: currentTrip)
            canManageAccess = tripStore.canManageAccess(trip: currentTrip)

            // Load permissions to show collaborators
            Task {
                await loadPermissions()
            }
        }
        .toolbar {
            // Only show add button if user can edit
            if canEdit {
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

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Share option (only owner can share)
                    if canManageAccess {
                        Button {
                            showingShareTrip = true
                        } label: {
                            Label("Share Trip", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            showingManageAccess = true
                        } label: {
                            Label("Manage Access", systemImage: "person.2.fill")
                        }

                        Divider()
                    }

                    // Only show edit options if user can edit
                    if canEdit {
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
                    }

                    // Only show delete if user is owner
                    if canDelete {
                        Divider()

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Trip", systemImage: "trash")
                        }
                    }

                    // Show viewer badge if not owner/editor
                    if !canEdit && !canDelete {
                        Text("Viewer")
                            .foregroundStyle(.secondary)
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
        .sheet(isPresented: $showingShareTrip) {
            ShareTripView(trip: currentTrip)
        }
        .sheet(isPresented: $showingManageAccess) {
            ManageAccessView(trip: currentTrip)
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

    private func loadPermissions() async {
        do {
            permissions = try await ConvexClient.shared.getTripPermissions(tripId: trip.id.uuidString)
        } catch {
            print("Error loading permissions: \(error)")
        }
    }

    private var collaboratorAvatars: some View {
        HStack(spacing: -8) {
            ForEach(permissions.prefix(3), id: \.id) { permission in
                ZStack {
                    // White border
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)

                    // Avatar - profile picture or initials
                    if let imageUrl = permission.user?.imageUrl, !imageUrl.isEmpty {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(avatarColor(for: permission.role).opacity(0.3))
                                .overlay {
                                    if let name = permission.user?.name, let first = name.first {
                                        Text(String(first).uppercased())
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(avatarColor(for: permission.role))
                                    } else {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(avatarColor(for: permission.role))
                                    }
                                }
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                    } else {
                        // Fallback to initials
                        Circle()
                            .fill(avatarColor(for: permission.role).opacity(0.3))
                            .frame(width: 24, height: 24)

                        if let name = permission.user?.name, let first = name.first {
                            Text(String(first).uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(avatarColor(for: permission.role))
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(avatarColor(for: permission.role))
                        }
                    }
                }
            }

            if permissions.count > 3 {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)

                    Circle()
                        .fill(.gray.opacity(0.2))
                        .frame(width: 24, height: 24)

                    Text("+\(permissions.count - 3)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.gray)
                }
            }
        }
    }

    private func avatarColor(for role: String) -> Color {
        switch role {
        case "owner": return .yellow
        case "collaborator": return .blue
        case "viewer": return .gray
        default: return .gray
        }
    }

    private var emptyMomentsState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "map.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.opacity(0.6))

            VStack(spacing: 12) {
                Text(canEdit ? "Start Your Story" : "No Moments Yet")
                    .font(.title)
                    .fontWeight(.bold)

                Text(canEdit
                     ? "Add photos and organize them into moments to create a beautiful visual journey"
                     : "This trip doesn't have any moments yet. Check back later!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            if canEdit {
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
            }

            Spacer()
        }
    }
}
