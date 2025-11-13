import SwiftUI

// Main spatial canvas view for displaying trip moments
struct TripCanvasView: View {
    let trip: Trip
    @State private var selectedMoment: Moment?
    @State private var showingExpandedMoment = false
    @State private var canvasSize: CGSize = .zero
    @State private var appearingMoments: Set<UUID> = []

    private var momentLayouts: [UUID: MomentLayout] {
        SpatialCanvasLayout.calculateLayout(
            for: trip.moments,
            canvasWidth: canvasSize.width
        )
    }

    private var sortedMoments: [Moment] {
        trip.moments.sorted { ($0.date ?? $0.timestamp) < ($1.date ?? $1.timestamp) }
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Only render if canvas has valid size
                    if canvasSize.width > 0 && canvasSize.height > 0 {
                        // Chronological flow paths
                        chronologicalPaths

                        // Moments on canvas with staggered entrance animations
                        ForEach(Array(trip.moments.enumerated()), id: \.element.id) { index, moment in
                            if let layout = momentLayouts[moment.id],
                               layout.size.width > 0,
                               layout.size.height > 0 {
                                MomentCardView(
                                    moment: moment,
                                    mediaItems: mediaItemsForMoment(moment),
                                    size: layout.size,
                                    onTap: {
                                        selectedMoment = moment
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            showingExpandedMoment = true
                                        }
                                    }
                                )
                                .position(x: layout.position.x + layout.size.width / 2,
                                         y: layout.position.y + layout.size.height / 2)
                                .zIndex(Double(layout.zIndex))
                                .scaleEffect(appearingMoments.contains(moment.id) ? 1.0 : 0.3)
                                .opacity(appearingMoments.contains(moment.id) ? 1.0 : 0.0)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.75)
                                        .delay(Double(index) * 0.1),
                                    value: appearingMoments
                                )
                            }
                        }
                    }
                }
                .frame(
                    width: geometry.size.width,
                    height: max(geometry.size.height, canvasContentHeight)
                )
            }
            .onAppear {
                if geometry.size.width > 0 && geometry.size.height > 0 {
                    canvasSize = geometry.size
                }

                // Trigger staggered entrance animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    for moment in trip.moments {
                        appearingMoments.insert(moment.id)
                    }
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                if newSize.width > 0 && newSize.height > 0 {
                    canvasSize = newSize
                }
            }
        }
        .overlay {
            if showingExpandedMoment, let moment = selectedMoment {
                ExpandedMomentView(
                    moment: moment,
                    mediaItems: mediaItemsForMoment(moment),
                    isPresented: $showingExpandedMoment
                )
            }
        }
    }

    // Draw paths connecting moments chronologically
    @ViewBuilder
    private var chronologicalPaths: some View {
        Canvas { context, size in
            guard sortedMoments.count > 1 else { return }

            var path = Path()

            for i in 0..<(sortedMoments.count - 1) {
                let currentMoment = sortedMoments[i]
                let nextMoment = sortedMoments[i + 1]

                guard let currentLayout = momentLayouts[currentMoment.id],
                      let nextLayout = momentLayouts[nextMoment.id] else {
                    continue
                }

                // Calculate center points
                let currentCenter = CGPoint(
                    x: currentLayout.position.x + currentLayout.size.width / 2,
                    y: currentLayout.position.y + currentLayout.size.height / 2
                )
                let nextCenter = CGPoint(
                    x: nextLayout.position.x + nextLayout.size.width / 2,
                    y: nextLayout.position.y + nextLayout.size.height / 2
                )

                // Draw curved path
                path.move(to: currentCenter)

                let controlPoint1 = CGPoint(
                    x: currentCenter.x + (nextCenter.x - currentCenter.x) * 0.3,
                    y: currentCenter.y
                )
                let controlPoint2 = CGPoint(
                    x: currentCenter.x + (nextCenter.x - currentCenter.x) * 0.7,
                    y: nextCenter.y
                )

                path.addCurve(to: nextCenter, control1: controlPoint1, control2: controlPoint2)
            }

            // Draw the path
            context.stroke(
                path,
                with: .color(.white.opacity(0.15)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 4])
            )
        }
    }

    private var canvasContentWidth: CGFloat {
        let maxX = momentLayouts.values.map { $0.position.x + $0.size.width }.max() ?? 0
        return maxX + 40 // Add right padding
    }

    private var canvasContentHeight: CGFloat {
        let maxY = momentLayouts.values.map { $0.position.y + $0.size.height }.max() ?? 0
        return maxY + 100 // Add bottom padding
    }

    private func mediaItemsForMoment(_ moment: Moment) -> [MediaItem] {
        trip.mediaItems.filter { moment.mediaItemIDs.contains($0.id) }
    }
}

#Preview {
    let sampleTrip = Trip(
        title: "Japan Adventure",
        startDate: Date(),
        endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
        moments: [
            Moment(
                title: "Tokyo Tower at Night",
                note: "Incredible city views",
                mediaItemIDs: [],
                placeName: "Tokyo Tower",
                importance: .hero
            ),
            Moment(
                title: "Ramen in Shibuya",
                note: "Best meal of the trip",
                mediaItemIDs: [],
                placeName: "Shibuya",
                importance: .medium
            ),
            Moment(
                title: "Temple Visit",
                note: "Peaceful and beautiful",
                mediaItemIDs: [],
                placeName: "Senso-ji",
                importance: .large
            )
        ]
    )

    TripCanvasView(trip: sampleTrip)
}
