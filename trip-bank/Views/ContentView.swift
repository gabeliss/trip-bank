import SwiftUI
import Clerk

struct ContentView: View {
    @EnvironmentObject var tripStore: TripStore
    @Environment(\.clerk) private var clerk
    @State private var showingNewTripSheet = false

    var body: some View {
        if clerk.user != nil {
            mainContent
                .task {
                    // Sync user to Convex database when authenticated
                    await syncUserToConvex()
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

    private var mainContent: some View {
        NavigationStack {
            ZStack {
                if tripStore.isLoading {
                    loadingView
                } else if tripStore.trips.isEmpty {
                    emptyStateView
                } else {
                    tripsList
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
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
                            Task {
                                await tripStore.loadTrips()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        Button(role: .destructive) {
                            Task {
                                try? await clerk.signOut()
                            }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingNewTripSheet) {
                NewTripView(trip: nil)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading trips...")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.on.rectangle")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)

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
}

#Preview {
    ContentView()
        .environmentObject(TripStore())
}
