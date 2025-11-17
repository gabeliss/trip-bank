import SwiftUI

struct ShareTripView: View {
    let trip: Trip
    @Environment(\.dismiss) var dismiss
    @State private var shareInfo: ShareLinkResponse?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCopiedAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Generating share link...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
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
                                await loadShareInfo()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxHeight: .infinity)
                } else if let info = shareInfo {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            VStack(spacing: 8) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.blue)

                                Text("Share \"\(trip.title)\"")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Anyone with this link can view your trip")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 20)

                            // Trip Code - Prominent Display
                            VStack(spacing: 8) {
                                Text("Trip Code")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                Text(info.shareCode)
                                    .font(.system(size: 42, weight: .bold, design: .rounded))
                                    .tracking(4)
                                    .foregroundStyle(.blue)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 24)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.blue.opacity(0.1))
                                    )
                                    .onTapGesture {
                                        copyToClipboard(info.shareCode)
                                    }

                                Text("Tap to copy")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)

                            // Share URL
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Share Link")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)

                                HStack {
                                    Text(info.url)
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                        .lineLimit(1)
                                        .truncationMode(.middle)

                                    Spacer()

                                    Button {
                                        copyToClipboard(info.url)
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            }

                            // Native Share Button
                            if let url = URL(string: info.url) {
                                ShareLink(
                                    item: url,
                                    subject: Text("Join my trip: \(trip.title)"),
                                    message: Text("Check out my \(trip.title) trip! Use code \(info.shareCode) or visit the link to join.")
                                ) {
                                    Label("Share Trip", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }

                            // Info Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "eye.fill")
                                        .foregroundStyle(.blue)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("New members join as viewers")
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Text("You can upgrade them to collaborators later")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Divider()

                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.blue)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("You control access")
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        Text("You can disable this link or remove members anytime")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )

                            Spacer(minLength: 40)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Share Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadShareInfo()
            }
            .alert("Copied!", isPresented: $showingCopiedAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func loadShareInfo() async {
        isLoading = true
        errorMessage = nil

        do {
            // Generate share link
            shareInfo = try await ConvexClient.shared.generateShareLink(tripId: trip.id.uuidString)
        } catch {
            errorMessage = error.localizedDescription
            print("Error generating share link: \(error)")
        }

        isLoading = false
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        showingCopiedAlert = true
    }
}
