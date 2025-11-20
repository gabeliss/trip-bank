import SwiftUI
import Clerk

struct ProfileSettingsView: View {
    @Environment(\.clerk) private var clerk
    @Environment(\.dismiss) private var dismiss

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

                // Friends Section (Coming Soon)
                Section {
                    NavigationLink {
                        ComingSoonView(feature: "Friends Management")
                    } label: {
                        Label("Friends", systemImage: "person.2.fill")
                    }
                } header: {
                    Text("Social")
                }

                // Subscription Section (Coming Soon)
                Section {
                    NavigationLink {
                        ComingSoonView(feature: "Subscription Management")
                    } label: {
                        Label("Manage Subscription", systemImage: "crown.fill")
                    }
                } header: {
                    Text("Subscription")
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
                        Task {
                            try? await clerk.signOut()
                        }
                    } label: {
                        HStack {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
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
        }
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
