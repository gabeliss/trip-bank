import SwiftUI
import Clerk
import AuthenticationServices

struct LoginView: View {
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // App Icon/Logo
            Image(systemName: "camera.on.rectangle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            // Title
            Text("TripBank")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your travel memories, beautifully organized")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            VStack(spacing: 16) {
                // Apple Sign In Button
                Button(action: { signInWithApple() }) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                        Text("Continue with Apple")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.white)
                    .background(Color.black)
                    .cornerRadius(12)
                }
                .disabled(isLoading)

                // Google Sign In Button
                Button(action: { signInWithGoogle() }) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 20))
                        Text("Continue with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.black)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 32)

            // Error Message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Privacy Text
            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
        }
        .padding()
    }

    func signInWithApple() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                // Get Apple credential using Clerk's helper
                let credential = try await SignInWithAppleHelper.getAppleIdCredential()

                // Convert the identityToken data to String format
                guard let idToken = credential.identityToken.flatMap({ String(data: $0, encoding: .utf8) }) else {
                    throw NSError(domain: "LoginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])
                }

                // Authenticate with Clerk
                try await SignIn.authenticateWithIdToken(provider: .apple, idToken: idToken)
            } catch {
                errorMessage = "Sign in with Apple failed. Please try again."
            }

            isLoading = false
        }
    }

    func signInWithGoogle() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                // Start the sign-in process with Google OAuth
                try await SignIn.authenticateWithRedirect(strategy: .oauth(provider: .google))
            } catch {
                errorMessage = "Sign in with Google failed. Please try again."
            }

            isLoading = false
        }
    }
}

#Preview {
    LoginView()
}
