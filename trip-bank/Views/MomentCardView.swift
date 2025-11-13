import SwiftUI
import AVKit

// Individual moment card displayed on the canvas
struct MomentCardView: View {
    let moment: Moment
    let mediaItems: [MediaItem]
    let size: CGSize
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Media content (photos/videos in collage)
            mediaContent

            // Enhanced gradient overlay for better text readability
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.3),
                    .black.opacity(0.85)
                ],
                startPoint: .init(x: 0.5, y: 0.4),
                endPoint: .bottom
            )

            // Text overlay with better hierarchy and contrast
            VStack(alignment: .leading, spacing: 6) {
                if let placeName = moment.placeName {
                    Text(placeName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.85))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }

                Text(moment.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                if let note = moment.note {
                    Text(note)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
            }
            .padding(16)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    @ViewBuilder
    private var mediaContent: some View {
        if mediaItems.isEmpty {
            // Placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else if mediaItems.count == 1 {
            // Single image or video
            singleMediaView(mediaItems[0])
        } else {
            // Collage for multiple images/videos
            collageLayout
        }
    }

    @ViewBuilder
    private func singleMediaView(_ mediaItem: MediaItem) -> some View {
        if mediaItem.type == .video, let videoURL = mediaItem.videoURL {
            AutoPlayVideoView(videoURL: videoURL)
                .frame(width: size.width, height: size.height)
        } else {
            MediaImageView(mediaItem: mediaItem)
                .scaledToFill()
                .frame(width: size.width, height: size.height)
        }
    }

    @ViewBuilder
    private var collageLayout: some View {
        // Ensure valid size before calculating
        let validWidth = max(1, size.width)
        let validHeight = max(1, size.height)

        if mediaItems.count == 2 {
            HStack(spacing: 2) {
                mediaItemView(mediaItems[0], width: validWidth / 2, height: validHeight)
                mediaItemView(mediaItems[1], width: validWidth / 2, height: validHeight)
            }
        } else if mediaItems.count == 3 {
            HStack(spacing: 2) {
                mediaItemView(mediaItems[0], width: validWidth * 0.6, height: validHeight)

                VStack(spacing: 2) {
                    mediaItemView(mediaItems[1], width: validWidth * 0.4, height: validHeight / 2)
                    mediaItemView(mediaItems[2], width: validWidth * 0.4, height: validHeight / 2)
                }
            }
        } else {
            // 4+ items: grid layout
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                ForEach(mediaItems.prefix(4).indices, id: \.self) { index in
                    mediaItemView(mediaItems[index], width: validWidth / 2 - 1, height: validHeight / 2 - 1)
                }
            }
        }
    }

    @ViewBuilder
    private func mediaItemView(_ mediaItem: MediaItem, width: CGFloat, height: CGFloat) -> some View {
        // Ensure valid dimensions
        let validWidth = max(1, width)
        let validHeight = max(1, height)

        if mediaItem.type == .video, let videoURL = mediaItem.videoURL {
            AutoPlayVideoView(videoURL: videoURL)
                .frame(width: validWidth, height: validHeight)
                .clipped()
        } else {
            MediaImageView(mediaItem: mediaItem)
                .scaledToFill()
                .frame(width: validWidth, height: validHeight)
                .clipped()
        }
    }
}
