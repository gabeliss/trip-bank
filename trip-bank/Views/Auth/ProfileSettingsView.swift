import SwiftUI
import Clerk

struct ProfileSettingsView: View {
    @Environment(\.clerk) private var clerk
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingSignOutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var showingFinalDeleteWarning = false
    @State private var isDeleting = false
    @State private var showingSubscriptionView = false

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section {
                    NavigationLink {
                        EditProfileView()
                    } label: {
                        HStack(spacing: 16) {
                            // Profile Photo
                            if let imageUrl = clerk.user?.imageUrl {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundStyle(.gray)
                                }
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundStyle(.gray)
                                    .frame(width: 70, height: 70)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                if let firstName = clerk.user?.firstName,
                                   let lastName = clerk.user?.lastName {
                                    Text("\(firstName) \(lastName)")
                                        .font(.headline)
                                } else if let firstName = clerk.user?.firstName {
                                    Text(firstName)
                                        .font(.headline)
                                }

                                if let email = clerk.user?.primaryEmailAddress?.emailAddress {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Account")
                }

                // Storage & Subscription Section
                Section {
                    // Storage usage row
                    if let usage = subscriptionManager.storageUsage {
                        Button {
                            showingSubscriptionView = true
                        } label: {
                            StorageUsageCompactView(usage: usage)
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack {
                            Label("Storage", systemImage: "externaldrive.fill")
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }

                    // Subscription row
                    Button {
                        showingSubscriptionView = true
                    } label: {
                        HStack {
                            Label("Subscription", systemImage: "crown.fill")
                                .foregroundStyle(subscriptionManager.currentTier == .pro ? .yellow : .primary)
                            Spacer()
                            Text(subscriptionManager.currentTier.displayName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Storage & Subscription")
                } footer: {
                    if subscriptionManager.currentTier == .free {
                        Text("Upgrade to Pro for 10 GB of storage")
                    }
                }

                // Support Section
                Section {
                    NavigationLink {
                        ComingSoonView(feature: "Feature Requests")
                    } label: {
                        Label("Submit Feature Request", systemImage: "lightbulb.fill")
                    }

                    Link(destination: URL(string: "mailto:support@tripbank.app")!) {
                        Label("Contact Support", systemImage: "envelope.fill")
                    }
                } header: {
                    Text("Support")
                }

                // Legal Section
                Section {
                    NavigationLink {
                        ComingSoonView(feature: "Privacy Policy")
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    NavigationLink {
                        ComingSoonView(feature: "Terms of Service")
                    } label: {
                        Label("Terms of Service", systemImage: "doc.text.fill")
                    }
                } header: {
                    Text("Legal")
                }

                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
                }

                // Delete Account Section
                Section {
                    Button(role: .destructive) {
                        showingDeleteAccountConfirmation = true
                    } label: {
                        HStack {
                            Label("Delete Account", systemImage: "trash.fill")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Permanently delete your account and all associated data. This action cannot be undone.")
                        .font(.caption)
                }
            }
            .navigationTitle("Profile & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Sign Out?", isPresented: $showingSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await clerk.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account?", isPresented: $showingDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    showingFinalDeleteWarning = true
                }
            } message: {
                Text("This will permanently delete your account and all your trips, photos, and data.")
            }
            .alert("Are You Absolutely Sure?", isPresented: $showingFinalDeleteWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
            } message: {
                Text("This action CANNOT be undone. All your data will be permanently deleted.")
            }
            .disabled(isDeleting)
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Deleting account...")
                                .foregroundStyle(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            }
            .sheet(isPresented: $showingSubscriptionView) {
                SubscriptionView()
            }
            .task {
                await subscriptionManager.fetchStorageUsage()
                await subscriptionManager.identifyUser()
            }
        }
    }

    private func deleteAccount() async {
        isDeleting = true

        do {
            // Delete all user data from Convex
            try await ConvexClient.shared.deleteAccount()

            // Delete account from Clerk
            try await clerk.user?.delete()

            // User will be automatically signed out when account is deleted
        } catch {
            print("❌ Error deleting account: \(error)")
            // Even if there's an error, try to sign out
            try? await clerk.signOut()
        }

        isDeleting = false
    }
}

// Placeholder view for features coming soon
struct ComingSoonView: View {
    let feature: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Coming Soon")
                .font(.title2)
                .fontWeight(.semibold)

            Text("\(feature) will be available in a future update.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle(feature)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileSettingsView()
}
