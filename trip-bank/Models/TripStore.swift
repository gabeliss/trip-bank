import Foundation
import SwiftUI

@MainActor
class TripStore: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let convexClient = ConvexClient.shared

    init() {
        // Load trips from Convex backend
        Task {
            await loadTrips()
        }
    }

    // MARK: - Load Trips from Backend

    func loadTrips() async {
        isLoading = true
        errorMessage = nil

        do {
            let convexTrips = try await convexClient.getAllTrips()

            // Convert Convex trips to local Trip objects
            var loadedTrips: [Trip] = []

            for convexTrip in convexTrips {
                // Fetch full trip details including media items and moments
                if let tripDetails = try await convexClient.getTrip(id: convexTrip.tripId) {
                    let mediaItems = tripDetails.mediaItems.map { $0.toMediaItem() }
                    let moments = tripDetails.moments.map { $0.toMoment() }

                    let trip = Trip(
                        id: UUID(uuidString: convexTrip.tripId) ?? UUID(),
                        title: convexTrip.title,
                        startDate: Date(timeIntervalSince1970: convexTrip.startDate / 1000),
                        endDate: Date(timeIntervalSince1970: convexTrip.endDate / 1000),
                        coverImageName: convexTrip.coverImageName,
                        mediaItems: mediaItems,
                        moments: moments
                    )
                    loadedTrips.append(trip)
                }
            }

            trips = loadedTrips
        } catch {
            errorMessage = "Failed to load trips: \(error.localizedDescription)"
            print("Error loading trips: \(error)")

            // Fallback to sample data if backend fails
            loadSampleData()
        }

        isLoading = false
    }

    // MARK: - Create Trip

    func addTrip(_ trip: Trip) {
        Task {
            do {
                // Save to backend
                _ = try await convexClient.createTrip(
                    id: trip.id.uuidString,
                    title: trip.title,
                    startDate: trip.startDate,
                    endDate: trip.endDate,
                    coverImageName: trip.coverImageName
                )

                // Update local state
                trips.append(trip)
            } catch {
                errorMessage = "Failed to create trip: \(error.localizedDescription)"
                print("Error creating trip: \(error)")
            }
        }
    }

    // MARK: - Delete Trip

    func deleteTrip(at indexSet: IndexSet) {
        for index in indexSet {
            let trip = trips[index]

            Task {
                do {
                    // Delete from backend
                    _ = try await convexClient.deleteTrip(id: trip.id.uuidString)

                    // Update local state
                    await MainActor.run {
                        trips.remove(atOffsets: indexSet)
                    }
                } catch {
                    errorMessage = "Failed to delete trip: \(error.localizedDescription)"
                    print("Error deleting trip: \(error)")
                }
            }
        }
    }

    // MARK: - Update Trip

    func updateTrip(_ trip: Trip) {
        Task {
            do {
                // Update on backend
                _ = try await convexClient.updateTrip(
                    id: trip.id.uuidString,
                    title: trip.title,
                    startDate: trip.startDate,
                    endDate: trip.endDate,
                    coverImageName: trip.coverImageName
                )

                // Update local state
                if let index = trips.firstIndex(where: { $0.id == trip.id }) {
                    trips[index] = trip
                }
            } catch {
                errorMessage = "Failed to update trip: \(error.localizedDescription)"
                print("Error updating trip: \(error)")
            }
        }
    }

    // MARK: - Media Items

    func addMediaItems(to tripID: UUID, mediaItems: [MediaItem]) {
        Task {
            do {
                // Save each media item to backend
                for mediaItem in mediaItems {
                    _ = try await convexClient.addMediaItem(
                        id: mediaItem.id.uuidString,
                        tripId: tripID.uuidString,
                        imageName: mediaItem.imageName,
                        imageURL: mediaItem.imageURL?.absoluteString,
                        videoURL: mediaItem.videoURL?.absoluteString,
                        storageId: mediaItem.storageId,
                        type: mediaItem.type.rawValue,
                        captureDate: mediaItem.captureDate,
                        note: mediaItem.note,
                        timestamp: mediaItem.timestamp
                    )
                }

                // Update local state
                if let index = trips.firstIndex(where: { $0.id == tripID }) {
                    trips[index].mediaItems.append(contentsOf: mediaItems)
                }
            } catch {
                errorMessage = "Failed to add media items: \(error.localizedDescription)"
                print("Error adding media items: \(error)")
            }
        }
    }

    // MARK: - Moments

    func addMoment(to tripID: UUID, moment: Moment) {
        Task {
            do {
                // Save to backend
                _ = try await convexClient.addMoment(
                    id: moment.id.uuidString,
                    tripId: tripID.uuidString,
                    title: moment.title,
                    note: moment.note,
                    mediaItemIDs: moment.mediaItemIDs.map { $0.uuidString },
                    timestamp: moment.timestamp,
                    date: moment.date,
                    placeName: moment.placeName,
                    eventName: moment.eventName,
                    voiceNoteURL: moment.voiceNoteURL,
                    importance: moment.importance.rawValue,
                    layoutPosition: moment.layoutPosition,
                    layoutSize: moment.layoutSize?.rawValue
                )

                // Update local state
                if let index = trips.firstIndex(where: { $0.id == tripID }) {
                    trips[index].moments.append(moment)
                }
            } catch {
                errorMessage = "Failed to add moment: \(error.localizedDescription)"
                print("Error adding moment: \(error)")
            }
        }
    }

    func updateMoment(in tripID: UUID, moment: Moment) {
        // Note: We would need to add an updateMoment mutation to Convex for this
        // For now, just update locally
        if let tripIndex = trips.firstIndex(where: { $0.id == tripID }),
           let momentIndex = trips[tripIndex].moments.firstIndex(where: { $0.id == moment.id }) {
            trips[tripIndex].moments[momentIndex] = moment
        }
    }

    func deleteMoment(from tripID: UUID, momentID: UUID) {
        // Note: We would need to add a deleteMoment mutation to Convex for this
        // For now, just delete locally
        if let tripIndex = trips.firstIndex(where: { $0.id == tripID }) {
            trips[tripIndex].moments.removeAll { $0.id == momentID }
        }
    }

    // MARK: - Sample Data
    private func loadSampleData() {
        // Create sample media items with placeholder images (using picsum.photos)
        // These are guaranteed to load and provide nice travel-related images
        let media1 = MediaItem(
            imageURL: URL(string: "https://picsum.photos/seed/lisbon1/800/800"),
            type: .photo
        )
        let media2 = MediaItem(
            imageURL: URL(string: "https://picsum.photos/seed/lisbon2/800/800"),
            type: .photo
        )
        let media3 = MediaItem(
            imageURL: URL(string: "https://picsum.photos/seed/belem/800/800"),
            type: .photo
        )
        let media4 = MediaItem(
            imageURL: URL(string: "https://picsum.photos/seed/pasteis/800/800"),
            type: .photo
        )
        let media5 = MediaItem(
            imageURL: URL(string: "https://picsum.photos/seed/tram1/800/800"),
            type: .photo
        )
        let media6 = MediaItem(
            imageURL: URL(string: "https://picsum.photos/seed/tram2/800/800"),
            type: .photo
        )
        let media7 = MediaItem(
            imageURL: URL(string: "https://picsum.photos/seed/fado/800/800"),
            type: .photo
        )
        let media8 = MediaItem(
            imageURL: URL(string: "https://picsum.photos/seed/cascais/800/800"),
            type: .photo
        )

        // Create sample moments to demonstrate the spatial canvas
        let sampleMoments = [
            Moment(
                title: "Sunset at Belém Tower",
                note: "One of the most iconic landmarks. The golden hour light was perfect.",
                mediaItemIDs: [media3.id],
                date: Calendar.current.date(byAdding: .day, value: -13, to: Date()),
                placeName: "Belém Tower",
                importance: .hero
            ),
            Moment(
                title: "Arrival in Lisbon",
                note: "First impressions of this beautiful city. The architecture is stunning!",
                mediaItemIDs: [media1.id, media2.id],
                date: Calendar.current.date(byAdding: .day, value: -14, to: Date()),
                placeName: "Lisbon Airport",
                importance: .medium
            ),
            Moment(
                title: "Pastéis de Nata Tasting",
                note: "Best custard tarts I've ever had. Warm from the oven!",
                mediaItemIDs: [media4.id],
                date: Calendar.current.date(byAdding: .day, value: -13, to: Date()),
                placeName: "Pastéis de Belém",
                importance: .small
            ),
            Moment(
                title: "Tram 28 Adventure",
                note: "Riding the famous yellow tram through narrow streets",
                mediaItemIDs: [media5.id, media6.id],
                date: Calendar.current.date(byAdding: .day, value: -12, to: Date()),
                placeName: "Alfama District",
                importance: .medium
            ),
            Moment(
                title: "Fado Night",
                note: "Traditional Portuguese music in a cozy restaurant. Emotional and beautiful.",
                mediaItemIDs: [media7.id],
                date: Calendar.current.date(byAdding: .day, value: -11, to: Date()),
                placeName: "Bairro Alto",
                eventName: "Fado Performance",
                importance: .large
            ),
            Moment(
                title: "Beach Day in Cascais",
                note: "Perfect day trip from Lisbon. Crystal clear water!",
                mediaItemIDs: [media8.id],
                date: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
                placeName: "Cascais Beach",
                importance: .large
            )
        ]

        // Create a sample trip
        let portugalTrip = Trip(
            title: "Portugal Adventure",
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            endDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            mediaItems: [media1, media2, media3, media4, media5, media6, media7, media8],
            moments: sampleMoments
        )

        trips = [portugalTrip]
    }
}
