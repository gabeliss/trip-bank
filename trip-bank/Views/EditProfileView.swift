import SwiftUI
import Clerk

struct EditProfileView: View {
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
                    Text("Profile Photo")
                }

                Section {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)

                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                } header: {
                    Text("Name")
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                // Initialize with current values
                firstName = clerk.user?.firstName ?? ""
                lastName = clerk.user?.lastName ?? ""
            }
            .disabled(isSaving)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileUIImage, profileImage: $profileImage)
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Saving...")
                                .foregroundStyle(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            }
        }
    }

    private func saveProfile() async {
        isSaving = true
        errorMessage = nil

        do {
            // Update profile picture if changed
            if let profileUIImage = profileUIImage {
                // Convert UIImage to Data
                guard let imageData = profileUIImage.jpegData(compressionQuality: 0.8) else {
                    throw ConvexError.convexError(message: "Failed to convert image to data")
                }

                // Set profile image using Clerk's API
                try await clerk.user?.setProfileImage(imageData: imageData)
            }

            // Update name
            try await clerk.user?.update(.init(
                firstName: firstName.isEmpty ? nil : firstName,
                lastName: lastName.isEmpty ? nil : lastName
            ))

            // Reload user data
            try await clerk.user?.reload()

            // Sync updated profile to Convex
            _ = try? await ConvexClient.shared.syncUser()

            dismiss()
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            print("❌ Error saving profile: \(error)")
        }

        isSaving = false
    }
}

// Image picker using UIImagePickerController for better simulator support
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var profileImage: Image?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
                parent.profileImage = Image(uiImage: editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
                parent.profileImage = Image(uiImage: originalImage)
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    EditProfileView()
}
