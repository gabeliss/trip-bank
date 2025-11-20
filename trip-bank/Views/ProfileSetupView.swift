import SwiftUI
import Clerk

struct ProfileSetupView: View {
    @Environment(\.clerk) private var clerk
    @Environment(\.dismiss) private var dismiss

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var showingImagePicker = false
    @State private var profileImage: Image?
    @State private var profileUIImage: UIImage?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                        .padding(.top, 40)

                    Text("Welcome to Rewinded!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Review your profile details and customize them if you'd like")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 32)

                // Form
                Form {
                    Section {
                        VStack(spacing: 16) {
                            // Profile Photo
                            ZStack(alignment: .bottomTrailing) {
                                if let profileImage = profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else if let imageUrl = clerk.user?.imageUrl {
                                    AsyncImage(url: URL(string: imageUrl)) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundStyle(.gray)
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundStyle(.gray)
                                        .frame(width: 120, height: 120)
                                }

                                // Edit button overlay
                                Button {
                                    showingImagePicker = true
                                } label: {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                        .padding(8)
                                        .background(Circle().fill(.blue))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    } header: {
                        Text("Profile Photo (Optional)")
                    }

                    Section {
                        TextField("First Name", text: $firstName)
                            .textContentType(.givenName)

                        TextField("Last Name", text: $lastName)
                            .textContentType(.familyName)
                    } header: {
                        Text("Name")
                    } footer: {
                        if firstName.isEmpty {
                            Text("First name is required")
                                .font(.caption)
                        }
                    }

                    if let errorMessage = errorMessage {
                        Section {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }

                // Continue Button
                VStack(spacing: 16) {
                    Button {
                        Task {
                            await saveProfile()
                        }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                                Text("Saving...")
                            } else {
                                Text("Continue")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(firstName.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(firstName.isEmpty || isSaving)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)

                    Button("Skip for now") {
                        markSetupComplete()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                    .disabled(isSaving)
                }
                .padding(.bottom, 32)
            }
            .navigationBarBackButtonHidden(true)
            .onAppear {
                // Pre-fill with OAuth data if available
                firstName = clerk.user?.firstName ?? ""
                lastName = clerk.user?.lastName ?? ""
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileUIImage, profileImage: $profileImage)
            }
        }
    }

    private func markSetupComplete() {
        if let userId = clerk.user?.id {
            UserDefaults.standard.set(true, forKey: "hasSeenProfileSetup_\(userId)")
        }
    }

    private func saveProfile() async {
        isSaving = true
        errorMessage = nil

        do {
            // Update profile picture if changed
            if let profileUIImage = profileUIImage {
                guard let imageData = profileUIImage.jpegData(compressionQuality: 0.8) else {
                    throw ConvexError.convexError(message: "Failed to convert image to data")
                }
                try await clerk.user?.setProfileImage(imageData: imageData)
            }

            // Update name (only if not empty)
            if !firstName.isEmpty {
                try await clerk.user?.update(.init(
                    firstName: firstName,
                    lastName: lastName.isEmpty ? nil : lastName
                ))
            }

            // Reload user data
            try await clerk.user?.reload()

            // Sync updated profile to Convex
            _ = try? await ConvexClient.shared.syncUser()

            // Mark setup as complete
            markSetupComplete()

            dismiss()
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            print("❌ Error saving profile: \(error)")
        }

        isSaving = false
    }
}

#Preview {
    ProfileSetupView()
}
