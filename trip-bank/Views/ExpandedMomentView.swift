import SwiftUI

// Full-screen expanded view of a moment
struct ExpandedMomentView: View {
    let moment: Moment
    let mediaItems: [MediaItem]
    @Binding var isPresented: Bool

    @State private var currentPhotoIndex = 0

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding()
                    }
                }

                // Media carousel (photos and videos)
                if !mediaItems.isEmpty {
                    TabView(selection: $currentPhotoIndex) {
                        ForEach(mediaItems.indices, id: \.self) { index in
                            let mediaItem = mediaItems[index]
                            if mediaItem.type == .video, let videoURL = mediaItem.videoURL {
                                AutoPlayVideoView(videoURL: videoURL)
                                    .scaledToFit()
                                    .tag(index)
                            } else {
                                MediaImageView(mediaItem: mediaItem)
                                    .scaledToFit()
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(maxHeight: 500)
                }

                // Moment details
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(moment.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    // Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        if let placeName = moment.placeName {
                            Label(placeName, systemImage: "mappin.circle.fill")
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        if let eventName = moment.eventName {
                            Label(eventName, systemImage: "star.fill")
                                .foregroundStyle(.white.opacity(0.9))
                        }

                        if let date = moment.date {
                            Label(formatDate(date), systemImage: "calendar")
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .font(.subheadline)

                    // Note
                    if let note = moment.note {
                        Text(note)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.top, 8)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
