import Foundation
import SwiftUI
import Clerk
import Combine
import ConvexMobile

@MainActor
class TripStore: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let convexClient = ConvexClient.shared
    private var cancellables = Set<AnyCancellable>()

    // Keep track of individual trip subscriptions
    private var tripSubscriptions: [String: AnyCancellable] = [:]

    // MARK: - Current User

    private var currentUserId: String? {
        return Clerk.shared.user?.id
    }

    init() {
        // Authentication and subscription will be triggered from ContentView
    }

    // MARK: - Real-Time Subscriptions

    /// Subscribe to real-time updates for the trip list
    func subscribeToTrips() {
        isLoading = true

        // Ensure authentication before subscribing
        Task {
            await convexClient.ensureLoggedIn()

            await MainActor.run {
                let subscription = convexClient.subscribe(to: "trips/trips:getAllTrips", yielding: [ConvexTrip].self)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { [weak self] completion in
                            if case .failure(let error) = completion {
                                self?.errorMessage = "Failed to load trips: \(error.localizedDescription)"
                                print("❌ [TripStore] Subscription error: \(error)")
                            }
                            self?.isLoading = false
                        },
                        receiveValue: { [weak self] convexTrips in
                            guard let self = self else { return }
                            print("✅ [TripStore] Received \(convexTrips.count) trips from subscription")

                            // Subscribe to detailed updates for each trip
                            Task {
                                await self.updateTripsWithDetails(convexTrips)
                            }
                        }
                    )
                self.cancellables.insert(subscription)
            }
        }
    }

    /// Subscribe to detailed trip data for each trip in the list
    private func updateTripsWithDetails(_ convexTrips: [ConvexTrip]) async {
        var updatedTrips: [Trip] = []

        for convexTrip in convexTrips {
            // Subscribe to this specific trip's details if not already subscribed
            if tripSubscriptions[convexTrip.tripId] == nil {
                subscribeTripDetails(tripId: convexTrip.tripId)
            }

            // For initial load, fetch the trip details
            do {
                if let tripDetails = try await fetchTripDetails(id: convexTrip.tripId) {
                    let trip = tripDetails
                    updatedTrips.append(trip)
                }
            } catch {
                print("❌ [TripStore] Failed to fetch trip details for \(convexTrip.tripId): \(error)")
            }
        }

        self.trips = updatedTrips
        self.isLoading = false
    }

    /// Subscribe to real-time updates for a specific trip's details
    /// This can be called for both "my trips" and "shared trips"
    func subscribeTripDetails(tripId: String) {
        // Don't subscribe twice
        guard tripSubscriptions[tripId] == nil else {
            print("ℹ️ [TripStore] Already subscribed to trip \(tripId)")
            return
        }

        print("📡 [TripStore] Subscribing to trip details for \(tripId)")

        let subscription = convexClient.subscribe(
            to: "trips/trips:getTrip",
            with: ["tripId": tripId],
            yielding: TripDetailsResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ [TripStore] Trip detail subscription error for \(tripId): \(error)")
                }
            },
            receiveValue: { [weak self] tripDetails in
                guard let self = self else { return }

                print("📥 [TripStore] Received trip update for \(tripId)")
                print("   userRole: \(tripDetails.trip.userRole ?? "nil")")

                // Convert to Trip model
                let mediaItems = tripDetails.mediaItems.map { $0.toMediaItem() }
                let moments = tripDetails.moments.map { $0.toMoment() }

                let trip = Trip(
                    id: UUID(uuidString: tripDetails.trip.tripId) ?? UUID(),
                    title: tripDetails.trip.title,
                    startDate: Date(timeIntervalSince1970: tripDetails.trip.startDate / 1000),
                    endDate: Date(timeIntervalSince1970: tripDetails.trip.endDate / 1000),
                    coverImageName: tripDetails.trip.coverImageName,
                    coverImageStorageId: tripDetails.trip.coverImageStorageId,
                    mediaItems: mediaItems,
                    moments: moments,
                    ownerId: tripDetails.trip.ownerId,
                    shareSlug: tripDetails.trip.shareSlug,
                    shareCode: tripDetails.trip.shareCode,
                    shareLinkEnabled: tripDetails.trip.shareLinkEnabled ?? false,
                    permissions: [],
                    userRole: tripDetails.trip.userRole,
                    joinedAt: nil
                )

                // Update the trip in the array
                if let index = self.trips.firstIndex(where: { $0.id.uuidString == tripId }) {
                    self.trips[index] = trip
                    print("✅ [TripStore] Updated trip \(tripId) in trips array")
                } else {
                    // If not in trips array, add it (this handles shared trips)
                    self.trips.append(trip)
                    print("✅ [TripStore] Added trip \(tripId) to trips array")
                }
            }
        )

        tripSubscriptions[tripId] = subscription
    }

    /// Helper method to fetch trip details (for initial load)
    private func fetchTripDetails(id: String) async throws -> Trip? {
        // Use HTTP query for initial fetch (subscriptions will handle updates)
        let url = URL(string: "https://flippant-mongoose-94.convex.cloud/api/query")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "path": "trips/trips:getTrip",
            "args": ["tripId": id]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let convexResponse = try JSONDecoder().decode(ConvexResponse<TripDetailsResponse?>.self, from: data)

        guard convexResponse.status == "success", let tripDetails = convexResponse.value else {
            return nil
        }

        let mediaItems = tripDetails.mediaItems.map { $0.toMediaItem() }
        let moments = tripDetails.moments.map { $0.toMoment() }

        return Trip(
            id: UUID(uuidString: tripDetails.trip.tripId) ?? UUID(),
            title: tripDetails.trip.title,
            startDate: Date(timeIntervalSince1970: tripDetails.trip.startDate / 1000),
            endDate: Date(timeIntervalSince1970: tripDetails.trip.endDate / 1000),
            coverImageName: tripDetails.trip.coverImageName,
            coverImageStorageId: tripDetails.trip.coverImageStorageId,
            mediaItems: mediaItems,
            moments: moments,
            ownerId: tripDetails.trip.ownerId,
            shareSlug: tripDetails.trip.shareSlug,
            shareCode: tripDetails.trip.shareCode,
            shareLinkEnabled: tripDetails.trip.shareLinkEnabled ?? false,
            permissions: [],
            userRole: tripDetails.trip.userRole,
            joinedAt: nil
        )
    }

    private func getAuthToken() async -> String? {
        guard let session = await Clerk.shared.session else { return nil }
        do {
            guard let tokenResource = try await session.getToken(.init(template: "convex")) else {
                return nil
            }
            return tokenResource.jwt
        } catch {
            return nil
        }
    }

    // MARK: - Manual Reload (for pull-to-refresh)

    func loadTrips() async {
        // Subscriptions handle this automatically, but we can force a refresh
        print("ℹ️ [TripStore] Manual refresh requested (subscriptions are already active)")
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

                // The subscription will automatically update the trips array
                print("✅ [TripStore] Trip created, waiting for subscription update...")
            } catch {
                errorMessage = "Failed to create trip: \(error.localizedDescription)"
                print("❌ [TripStore] Error creating trip: \(error)")
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

                    // Cancel subscription for this trip
                    tripSubscriptions[trip.id.uuidString]?.cancel()
                    tripSubscriptions.removeValue(forKey: trip.id.uuidString)

                    // The subscription will automatically update the trips array
                    print("✅ [TripStore] Trip deleted, waiting for subscription update...")
                } catch {
                    errorMessage = "Failed to delete trip: \(error.localizedDescription)"
                    print("❌ [TripStore] Error deleting trip: \(error)")
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

                // The subscription will automatically update the trips array
                print("✅ [TripStore] Trip updated, waiting for subscription update...")
            } catch {
                errorMessage = "Failed to update trip: \(error.localizedDescription)"
                print("❌ [TripStore] Error updating trip: \(error)")
            }
        }
    }

    // MARK: - Media Items

    func addMediaItems(to tripID: UUID, mediaItems: [MediaItem]) {
        // Optimistic update
        if let index = trips.firstIndex(where: { $0.id == tripID }) {
            trips[index].mediaItems.append(contentsOf: mediaItems)
        }

        // Save to backend
        Task {
            do {
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
                        timestamp: mediaItem.timestamp.timeIntervalSince1970,
                        fileSize: mediaItem.fileSize,
                        thumbnailSize: mediaItem.thumbnailSize
                    )
                }

                // The subscription will update cover image automatically
                print("✅ [TripStore] Media items added, waiting for subscription update...")
            } catch {
                errorMessage = "Failed to add media items: \(error.localizedDescription)"
                print("❌ [TripStore] Error adding media items: \(error)")

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
        // Optimistic update
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
                    timestamp: moment.timestamp.timeIntervalSince1970,
                    date: moment.date,
                    placeName: moment.placeName,
                    voiceNoteURL: moment.voiceNoteURL,
                    gridPosition: moment.gridPosition
                )

                print("✅ [TripStore] Moment added, waiting for subscription update...")
            } catch {
                errorMessage = "Failed to add moment: \(error.localizedDescription)"
                print("❌ [TripStore] Failed to add moment: \(error)")

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
                _ = try await convexClient.updateMoment(
                    id: moment.id.uuidString,
                    title: moment.title,
                    note: moment.note,
                    mediaItemIDs: moment.mediaItemIDs.map { $0.uuidString },
                    date: moment.date,
                    placeName: moment.placeName
                )

                // The subscription will automatically update
                print("✅ [TripStore] Moment updated, waiting for subscription update...")
            } catch {
                errorMessage = "Failed to update moment: \(error.localizedDescription)"
                print("❌ [TripStore] Error updating moment: \(error)")
            }
        }
    }

    func deleteMoment(from tripID: UUID, momentID: UUID) {
        Task {
            do {
                _ = try await convexClient.deleteMoment(id: momentID.uuidString)

                // The subscription will automatically update
                print("✅ [TripStore] Moment deleted, waiting for subscription update...")
            } catch {
                errorMessage = "Failed to delete moment: \(error.localizedDescription)"
                print("❌ [TripStore] Error deleting moment: \(error)")
            }
        }
    }

    // MARK: - Delete Media Item

    func deleteMediaItem(from tripID: UUID, mediaItemID: UUID) {
        Task {
            do {
                _ = try await convexClient.deleteMediaItem(id: mediaItemID.uuidString)

                // The subscription will automatically update
                print("✅ [TripStore] Media item deleted, waiting for subscription update...")
            } catch {
                errorMessage = "Failed to delete media item: \(error.localizedDescription)"
                print("❌ [TripStore] Error deleting media item: \(error)")
            }
        }
    }

    // MARK: - Update Media Item

    func updateMediaItem(in tripID: UUID, mediaItem: MediaItem) {
        Task {
            do {
                _ = try await convexClient.updateMediaItem(
                    id: mediaItem.id.uuidString,
                    note: mediaItem.note,
                    captureDate: mediaItem.captureDate
                )

                // The subscription will automatically update
                print("✅ [TripStore] Media item updated, waiting for subscription update...")
            } catch {
                errorMessage = "Failed to update media item: \(error.localizedDescription)"
                print("❌ [TripStore] Error updating media item: \(error)")
            }
        }
    }

    // MARK: - Permissions

    /// Check if current user can view a trip
    func canView(trip: Trip) -> Bool {
        guard let userId = currentUserId else { return false }

        // Owner can view
        if trip.ownerId == userId { return true }

        // Check permissions
        return trip.permissions.contains { $0.userId == userId }
    }

    /// Check if current user can edit a trip (add/modify/delete content)
    func canEdit(trip: Trip) -> Bool {
        guard let userId = currentUserId else { return false }

        // Owner can edit
        if trip.ownerId == userId { return true }

        // For shared trips, check userRole from backend
        if let userRole = trip.userRole {
            return userRole == "collaborator"
        }

        // Fallback to permissions array (for backward compatibility)
        return trip.permissions.contains {
            $0.userId == userId && $0.role == .collaborator
        }
    }

    /// Check if current user can manage access (invite users, change permissions)
    func canManageAccess(trip: Trip) -> Bool {
        guard let userId = currentUserId else { return false }

        // Only owner can manage access
        return trip.ownerId == userId
    }

    /// Check if current user is the owner of a trip
    func isOwner(trip: Trip) -> Bool {
        guard let userId = currentUserId else { return false }
        return trip.ownerId == userId
    }
}

// MARK: - Response Types

struct TripDetailsResponse: Decodable {
    let trip: ConvexTripDetailed
    let mediaItems: [ConvexMediaItem]
    let moments: [ConvexMoment]
}

struct ConvexTripDetailed: Decodable {
    let tripId: String
    let title: String
    let startDate: Double
    let endDate: Double
    let coverImageName: String?
    let coverImageStorageId: String?
    let ownerId: String
    let shareSlug: String?
    let shareCode: String?
    let shareLinkEnabled: Bool?
    let userRole: String?
}
