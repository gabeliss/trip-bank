import SwiftUI
import Clerk

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

    var body: some View {
        if clerk.user != nil {
            mainContent
                .task {
                    // Sync user to Convex database when authenticated
                    await syncUserToConvex()
                    // Load shared trips on initial load
                    await loadSharedTrips()
                    // Check if user needs to complete profile setup
                    checkProfileSetup()
                }
                .onChange(of: selectedTab) { _, newTab in
                    if newTab == .sharedWithMe {
                        Task {
                            await loadSharedTrips()
                        }
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
                    Menu {
                        Button {
                            showingJoinTrip = true
                        } label: {
                            Label("Join Trip", systemImage: "ticket")
                        }

                        Divider()

                        Button {
                            Task {
                                await tripStore.loadTrips()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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

    private func loadSharedTrips() async {
        isLoadingShared = true
        do {
            let convexTrips = try await ConvexClient.shared.getSharedTrips()

            // Convert Convex trips to local Trip objects
            var loadedTrips: [Trip] = []

            for convexTrip in convexTrips {
                // Fetch full trip details including media items and moments
                if let tripDetails = try await ConvexClient.shared.getTrip(id: convexTrip.tripId) {
                    let mediaItems = tripDetails.mediaItems.map { $0.toMediaItem() }
                    let moments = tripDetails.moments.map { $0.toMoment() }

                    let trip = Trip(
                        id: UUID(uuidString: convexTrip.tripId) ?? UUID(),
                        title: convexTrip.title,
                        startDate: Date(timeIntervalSince1970: convexTrip.startDate / 1000),
                        endDate: Date(timeIntervalSince1970: convexTrip.endDate / 1000),
                        coverImageStorageId: convexTrip.coverImageStorageId,
                        mediaItems: mediaItems,
                        moments: moments,
                        ownerId: tripDetails.trip.ownerId,
                        shareSlug: tripDetails.trip.shareSlug,
                        shareCode: tripDetails.trip.shareCode,
                        shareLinkEnabled: tripDetails.trip.shareLinkEnabled ?? false,
                        permissions: [],
                        userRole: convexTrip.userRole,
                        joinedAt: convexTrip.joinedAt
                    )

                    loadedTrips.append(trip)
                }
            }

            sharedTrips = loadedTrips
        } catch {
            print("Error loading shared trips: \(error)")
        }
        isLoadingShared = false
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
                    // Reload both my trips and shared trips
                    await tripStore.loadTrips()
                    await loadSharedTrips()
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
