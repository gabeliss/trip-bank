import SwiftUI

struct ManageAccessView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var tripStore: TripStore
    @State private var permissions: [TripPermissionWithUser] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingRemoveConfirmation = false
    @State private var userToRemove: TripPermissionWithUser?

    // Check if current user is owner
    private var isOwner: Bool {
        tripStore.isOwner(trip: trip)
    }

    // Check if current user is a collaborator
    private var isCollaborator: Bool {
        tripStore.canEdit(trip: trip) && !isOwner
    }

    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.orange)

                        Text("Error")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(error)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Try Again") {
                            Task {
                                await loadPermissions()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {
                            ForEach(permissions, id: \.id) { permission in
                                PermissionRow(
                                    permission: permission,
                                    isOwner: isOwner,
                                    isCollaborator: isCollaborator,
                                    onRoleChange: { newRole in
                                        Task {
                                            await updateRole(permission: permission, newRole: newRole)
                                        }
                                    },
                                    onRemove: {
                                        userToRemove = permission
                                        showingRemoveConfirmation = true
                                    }
                                )
                            }
                        } header: {
                            Text("\(permissions.count) \(permissions.count == 1 ? "person" : "people") with access")
                        }

                        Section {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Collaborators can add photos and create moments. Viewers can only see the trip.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Access")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadPermissions()
            }
            .alert("Remove Access?", isPresented: $showingRemoveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if let user = userToRemove {
                        Task {
                            await removeUser(permission: user)
                        }
                    }
                }
            } message: {
                if let user = userToRemove, let name = user.user?.name {
                    Text("Remove \(name) from this trip? They will no longer have access.")
                } else {
                    Text("Remove this person from the trip? They will no longer have access.")
                }
            }
        }
    }

    private func loadPermissions() async {
        isLoading = true
        errorMessage = nil

        do {
            permissions = try await ConvexClient.shared.getTripPermissions(tripId: trip.id.uuidString)
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading permissions: \(error)")
        }

        isLoading = false
    }

    private func updateRole(permission: TripPermissionWithUser, newRole: String) async {
        do {
            _ = try await ConvexClient.shared.updatePermission(
                tripId: trip.id.uuidString,
                userId: permission.userId,
                newRole: newRole
            )

            // Reload permissions (real-time subscription in TripDetailView will also update)
            await loadPermissions()
        } catch {
            errorMessage = error.localizedDescription
            print("Error updating permission: \(error)")
        }
    }

    private func removeUser(permission: TripPermissionWithUser) async {
        do {
            _ = try await ConvexClient.shared.removeAccess(
                tripId: trip.id.uuidString,
                userId: permission.userId
            )

            // Reload permissions (real-time subscription in TripDetailView will also update)
            await loadPermissions()
        } catch {
            errorMessage = error.localizedDescription
            print("Error removing user: \(error)")
        }
    }
}

struct PermissionRow: View {
    let permission: TripPermissionWithUser
    let isOwner: Bool
    let isCollaborator: Bool
    let onRoleChange: (String) -> Void
    let onRemove: () -> Void

    // Owner can edit anyone (except themselves)
    // Collaborator can only edit viewers
    private var canEditThisUser: Bool {
        if permission.role == "owner" { return false } // No one can edit owner
        if isOwner { return true } // Owner can edit collaborators and viewers
        if isCollaborator && permission.role == "viewer" { return true } // Collaborator can edit viewers
        return false
    }

    private var displayName: String {
        permission.user?.name ?? permission.user?.email ?? "Unknown User"
    }

    private var displayEmail: String? {
        if permission.user?.name != nil {
            return permission.user?.email
        }
        return nil
    }

    private var roleIcon: String {
        switch permission.role {
        case "owner": return "crown.fill"
        case "collaborator": return "pencil.circle.fill"
        case "viewer": return "eye.fill"
        default: return "person.fill"
        }
    }

    private var roleColor: Color {
        switch permission.role {
        case "owner": return .yellow
        case "collaborator": return .blue
        case "viewer": return .gray
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Avatar - profile picture or initials
            if let imageUrl = permission.user?.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(roleColor.opacity(0.2))
                        .overlay {
                            if let name = permission.user?.name, let first = name.first {
                                Text(String(first).uppercased())
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(roleColor)
                            } else {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(roleColor)
                            }
                        }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            } else {
                // Fallback to initials if no image
                ZStack {
                    Circle()
                        .fill(roleColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    if let name = permission.user?.name, let first = name.first {
                        Text(String(first).uppercased())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(roleColor)
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundStyle(roleColor)
                    }
                }
            }

            // Name and email
            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .font(.body)
                    .fontWeight(.medium)

                if let email = displayEmail {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Role badge and actions
            if canEditThisUser {
                // Show menu if user can edit this permission
                Menu {
                    if permission.role == "viewer" {
                        Button {
                            onRoleChange("collaborator")
                        } label: {
                            Label("Make Collaborator", systemImage: "pencil.circle")
                        }
                    } else if permission.role == "collaborator" {
                        Button {
                            onRoleChange("viewer")
                        } label: {
                            Label("Change to Viewer", systemImage: "eye")
                        }
                    }

                    // Only owner can remove users
                    if isOwner {
                        Divider()

                        Button(role: .destructive) {
                            onRemove()
                        } label: {
                            Label("Remove Access", systemImage: "person.fill.xmark")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: roleIcon)
                            .font(.caption)
                        Text(permission.role.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundStyle(roleColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(roleColor.opacity(0.15))
                    .cornerRadius(8)
                }
            } else {
                // Just show role badge (can't edit this user)
                HStack(spacing: 4) {
                    Image(systemName: roleIcon)
                        .font(.caption)
                    Text(permission.role.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(roleColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(roleColor.opacity(0.15))
                .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}
