import SwiftUI

struct TripCardView: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image or placeholder
            coverImage
                .frame(height: 200)
                .clipped()

            // Trip info
            VStack(alignment: .leading, spacing: 8) {
                Text(trip.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(trip.dateRangeString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    Label("\(trip.mediaItems.count)", systemImage: "photo")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !trip.moments.isEmpty {
                        Label("\(trip.moments.count)", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    @ViewBuilder
    private var coverImage: some View {
        if let coverImageName = trip.coverImageName {
            Image(coverImageName)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    VStack {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 50))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
        }
    }
}

#Preview {
    TripCardView(trip: Trip(title: "Portugal Adventure"))
        .padding()
}
