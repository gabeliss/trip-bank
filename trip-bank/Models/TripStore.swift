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
                        coverImageStorageId: convexTrip.coverImageStorageId,
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
                    coverImageName: trip.coverImageName,
                    coverImageStorageId: trip.coverImageStorageId
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
        // Update local state immediately (optimistic update)
        if let index = trips.firstIndex(where: { $0.id == tripID }) {
            trips[index].mediaItems.append(contentsOf: mediaItems)
        }

        // Save to backend
        Task {
            do {
                // Save each media item to backend
                for mediaItem in mediaItems {
                    _ = try await convexClient.addMediaItem(
                        id: mediaItem.id.uuidString,
                        tripId: tripID.uuidString,
                        imageURL: mediaItem.imageURL?.absoluteString,
                        videoURL: mediaItem.videoURL?.absoluteString,
                        storageId: mediaItem.storageId,
                        thumbnailStorageId: mediaItem.thumbnailStorageId,
                        type: mediaItem.type.rawValue,
                        captureDate: mediaItem.captureDate,
                        note: mediaItem.note,
                        timestamp: mediaItem.timestamp
                    )
                }

                // Reload trip to get updated cover image (backend auto-sets it for first photo)
                if let tripDetails = try await convexClient.getTrip(id: tripID.uuidString) {
                    if let index = trips.firstIndex(where: { $0.id == tripID }) {
                        trips[index].coverImageStorageId = tripDetails.trip.coverImageStorageId
                        trips[index].coverImageName = tripDetails.trip.coverImageName
                    }
                }
            } catch {
                errorMessage = "Failed to add media items: \(error.localizedDescription)"
                print("Error adding media items: \(error)")

                // Rollback on failure
                if let index = trips.firstIndex(where: { $0.id == tripID }) {
                    let mediaItemIDs = Set(mediaItems.map { $0.id })
                    trips[index].mediaItems.removeAll { mediaItemIDs.contains($0.id) }
                }
            }
        }
    }

    // MARK: - Moments

    func addMoment(to tripID: UUID, moment: Moment) {
        // Update local state immediately (optimistic update)
        if let index = trips.firstIndex(where: { $0.id == tripID }) {
            trips[index].moments.append(moment)
        }

        // Save to backend
        Task {
            do {
                _ = try await convexClient.addMoment(
                    id: moment.id.uuidString,
                    tripId: tripID.uuidString,
                    title: moment.title,
                    note: moment.note,
                    mediaItemIDs: moment.mediaItemIDs.map { $0.uuidString },
                    timestamp: moment.timestamp,
                    date: moment.date,
                    placeName: moment.placeName,
                    voiceNoteURL: moment.voiceNoteURL,
                    gridPosition: moment.gridPosition
                )
            } catch {
                errorMessage = "Failed to add moment: \(error.localizedDescription)"
                print("❌ Failed to add moment: \(error)")

                // Rollback on failure
                if let index = trips.firstIndex(where: { $0.id == tripID }) {
                    trips[index].moments.removeAll { $0.id == moment.id }
                }
            }
        }
    }

    func updateMoment(in tripID: UUID, moment: Moment) {
        Task {
            do {
                // Update on backend
                _ = try await convexClient.updateMoment(
                    id: moment.id.uuidString,
                    title: moment.title,
                    note: moment.note,
                    mediaItemIDs: moment.mediaItemIDs.map { $0.uuidString },
                    date: moment.date,
                    placeName: moment.placeName
                )

                // Update local state
                if let tripIndex = trips.firstIndex(where: { $0.id == tripID }),
                   let momentIndex = trips[tripIndex].moments.firstIndex(where: { $0.id == moment.id }) {
                    trips[tripIndex].moments[momentIndex] = moment
                }
            } catch {
                errorMessage = "Failed to update moment: \(error.localizedDescription)"
                print("Error updating moment: \(error)")
            }
        }
    }

    func deleteMoment(from tripID: UUID, momentID: UUID) {
        Task {
            do {
                // Delete from backend
                _ = try await convexClient.deleteMoment(id: momentID.uuidString)

                // Update local state
                if let tripIndex = trips.firstIndex(where: { $0.id == tripID }) {
                    trips[tripIndex].moments.removeAll { $0.id == momentID }
                }
            } catch {
                errorMessage = "Failed to delete moment: \(error.localizedDescription)"
                print("Error deleting moment: \(error)")
            }
        }
    }

    // MARK: - Delete Media Item

    func deleteMediaItem(from tripID: UUID, mediaItemID: UUID) {
        Task {
            do {
                // Delete from backend (also removes from moments via cascade)
                _ = try await convexClient.deleteMediaItem(id: mediaItemID.uuidString)

                // Update local state
                if let tripIndex = trips.firstIndex(where: { $0.id == tripID }) {
                    // Remove media item
                    trips[tripIndex].mediaItems.removeAll { $0.id == mediaItemID }

                    // Remove from all moments that reference it
                    for momentIndex in trips[tripIndex].moments.indices {
                        trips[tripIndex].moments[momentIndex].mediaItemIDs.removeAll { $0 == mediaItemID }
                    }
                }
            } catch {
                errorMessage = "Failed to delete media item: \(error.localizedDescription)"
                print("Error deleting media item: \(error)")
            }
        }
    }

    // MARK: - Update Media Item

    func updateMediaItem(in tripID: UUID, mediaItem: MediaItem) {
        Task {
            do {
                // Update on backend
                _ = try await convexClient.updateMediaItem(
                    id: mediaItem.id.uuidString,
                    note: mediaItem.note,
                    captureDate: mediaItem.captureDate
                )

                // Update local state
                if let tripIndex = trips.firstIndex(where: { $0.id == tripID }),
                   let mediaIndex = trips[tripIndex].mediaItems.firstIndex(where: { $0.id == mediaItem.id }) {
                    trips[tripIndex].mediaItems[mediaIndex] = mediaItem
                }
            } catch {
                errorMessage = "Failed to update media item: \(error.localizedDescription)"
                print("Error updating media item: \(error)")
            }
        }
    }

}
