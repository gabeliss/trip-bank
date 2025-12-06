import SwiftUI
import Clerk
import Combine
import ConvexMobile

enum TripTab {
    case myTrips
    case sharedWithMe
}

struct ContentView: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.clerk) private var clerk
    @State private var showingNewTripSheet = false
    @State private var showingJoinTrip = false
    @State private var selectedTab: TripTab = .myTrips
    @State private var sharedTrips: [Trip] = []
    @State private var isLoadingShared = false
    @State private var showingProfileSettings = false
    @State private var needsProfileSetup = false
    @Binding var pendingShareSlug: String?

    // Real-time subscription management
    @State private var sharedTripsSubscription: AnyCancellable?

    var body: some View {
        if clerk.user != nil {
            mainContent
                .task {
                    // Sync user to Convex database when authenticated
                    await syncUserToConvex()
                    // Start real-time subscriptions for trips
                    tripStore.subscribeToTrips()
                    // Load shared trips on initial load
                    await loadSharedTrips()
                    // Check if user needs to complete profile setup
                    checkProfileSetup()
                }
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == .sharedWithMe {
                        // Subscribe to shared trips when switching to that tab
                        subscribeToSharedTrips()
                    }
                }
                .onChange(of: pendingShareSlug) { _, slug in
                    if let slug = slug, clerk.user != nil {
                        handleDeepLinkJoin(slug: slug)
                    }
                }
        } else {
            LoginView()
        }
    }

    private func syncUserToConvex() async {
        do {
            let user = try await ConvexClient.shared.syncUser()
            print("✅ User synced to Convex: \(user?.email ?? "unknown")")
        } catch {
            print("❌ Failed to sync user to Convex: \(error)")
        }
    }

    private func checkProfileSetup() {
        // Check if user has seen the profile setup screen
        let hasSeenProfileSetup = UserDefaults.standard.bool(forKey: "hasSeenProfileSetup_\(clerk.user?.id ?? "")")

        // Show setup screen on first login (even if OAuth provided name/photo)
        if !hasSeenProfileSetup {
            needsProfileSetup = true
        }
    }

    private var mainContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Trips", selection: $selectedTab) {
                    Text("My Trips").tag(TripTab.myTrips)
                    Text("Shared with Me").tag(TripTab.sharedWithMe)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // Content based on selected tab
                ZStack {
                    if selectedTab == .myTrips {
                        if tripStore.isLoading {
                            loadingView
                        } else if tripStore.trips.isEmpty {
                            emptyStateView
                        } else {
                            tripsList
                        }
                    } else {
                        if isLoadingShared {
                            loadingView
                        } else if sharedTrips.isEmpty {
                            emptySharedTripsView
                        } else {
                            sharedTripsList
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Rewinded")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingProfileSettings = true
                    } label: {
                        if let imageUrl = clerk.user?.imageUrl {
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewTripSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingJoinTrip = true
                    } label: {
                        Image(systemName: "ticket")
                    }
                }
            }
            .sheet(isPresented: $showingNewTripSheet) {
                NewTripView(trip: nil)
            }
            .sheet(isPresented: $showingJoinTrip) {
                JoinTripView()
            }
            .sheet(isPresented: $showingProfileSettings) {
                ProfileSettingsView()
            }
            .fullScreenCover(isPresented: $needsProfileSetup) {
                ProfileSetupView()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding(.top, 40)
            Text("Loading trips...")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.on.rectangle")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)
                .padding(.top, 40)

            Text("No Trips Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create your first trip to start sharing your adventures")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingNewTripSheet = true
            } label: {
                Label("Create Trip", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
    }

    private var tripsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(tripStore.trips) { trip in
                    NavigationLink {
                        TripDetailView(trip: trip)
                    } label: {
                        TripCardView(trip: trip)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private var emptySharedTripsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)
                .padding(.top, 40)

            Text("No Shared Trips")
                .font(.title2)
                .fontWeight(.semibold)

            Text("When someone shares a trip with you, it will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingJoinTrip = true
            } label: {
                Label("Join Trip", systemImage: "ticket")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
    }

    private var sharedTripsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sharedTrips) { trip in
                    NavigationLink {
                        TripDetailView(trip: trip)
                    } label: {
                        SharedTripCardView(trip: trip)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    /// Subscribe to real-time updates for shared trips
    private func subscribeToSharedTrips() {
        guard sharedTripsSubscription == nil else {
            print("ℹ️ [ContentView] Already subscribed to shared trips")
            return
        }

        isLoadingShared = true

        Task {
            // Ensure authentication before subscribing
            await ConvexClient.shared.ensureLoggedIn()

            sharedTripsSubscription = ConvexClient.shared.subscribe(
                to: "trips/sharing:getSharedTrips",
                yielding: [ConvexTrip].self
            )
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    if case .failure(let error) = completion {
                        print("❌ [ContentView] Shared trips subscription error: \(error)")
                    }
                    isLoadingShared = false
                },
                receiveValue: { [self] convexTrips in
                    print("✅ [ContentView] Received \(convexTrips.count) shared trips from subscription")

                    Task {
                        await updateSharedTripsWithDetails(convexTrips)
                    }
                }
            )
        }
    }

    private func updateSharedTripsWithDetails(_ convexTrips: [ConvexTrip]) async {
        var updatedTrips: [Trip] = []

        for convexTrip in convexTrips {
            // Fetch trip details for each shared trip
            do {
                if let tripDetails = try await fetchTripDetails(id: convexTrip.tripId) {
                    var trip = tripDetails
                    trip.userRole = convexTrip.userRole
                    trip.joinedAt = convexTrip.joinedAt
                    updatedTrips.append(trip)
                }
            } catch {
                print("❌ [ContentView] Failed to fetch shared trip details: \(error)")
            }
        }

        sharedTrips = updatedTrips
        isLoadingShared = false
    }

    private func fetchTripDetails(id: String) async throws -> Trip? {
        // Use HTTP query for initial fetch
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
        guard let session = await clerk.session else { return nil }
        do {
            guard let tokenResource = try await session.getToken(.init(template: "convex")) else {
                return nil
            }
            return tokenResource.jwt
        } catch {
            return nil
        }
    }

    private func loadSharedTrips() async {
        // Called on initial load - subscription will handle updates
        subscribeToSharedTrips()
    }

    private func handleDeepLinkJoin(slug: String) {
        Task {
            do {
                let response = try await ConvexClient.shared.joinTripViaLink(
                    shareSlug: slug,
                    shareCode: nil
                )

                if response.alreadyMember {
                    print("Already a member of this trip")
                } else {
                    print("✅ Successfully joined trip via deep link!")
                    // Subscriptions will automatically update the trip lists
                    // Switch to shared trips tab to show the newly joined trip
                    selectedTab = .sharedWithMe
                }

                // Clear the pending slug
                pendingShareSlug = nil
            } catch {
                print("❌ Error joining trip via deep link: \(error)")
                pendingShareSlug = nil
            }
        }
    }
}

#Preview {
    ContentView(pendingShareSlug: .constant(nil))
        .environmentObject(TripStore())
}
