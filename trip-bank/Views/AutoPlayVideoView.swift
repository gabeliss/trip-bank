import SwiftUI
import AVKit

// Auto-playing video view that loops and is muted by default
struct AutoPlayVideoView: View {
    let videoURL: URL
    @State private var player: AVPlayer?
    @State private var isMuted = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true) // Disable default controls
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }

                // Mute/unmute button
                Button {
                    isMuted.toggle()
                    player.isMuted = isMuted
                } label: {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(.black.opacity(0.5)))
                }
                .padding(8)
            }
        }
        .onAppear {
            setupPlayer()
        }
    }

    private func setupPlayer() {
        let player = AVPlayer(url: videoURL)
        player.isMuted = isMuted
        player.actionAtItemEnd = .none

        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        self.player = player
    }
}

// Simpler non-interactive auto-play video for collages
struct CollageVideoView: View {
    let videoURL: URL
    @State private var player: AVPlayer?

    var body: some View {
        if let player = player {
            VideoPlayer(player: player)
                .disabled(true)
                .onAppear {
                    player.play()
                }
                .onDisappear {
                    player.pause()
                }
        }
    }

    func setupPlayer() {
        let player = AVPlayer(url: videoURL)
        player.isMuted = true
        player.actionAtItemEnd = .none

        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        self.player = player
    }
}
