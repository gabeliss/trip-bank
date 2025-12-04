import SwiftUI
import Clerk
import RevenueCat

@main
struct TripBankApp: App {
    @StateObject private var tripStore = TripStore()
    @State private var clerk = Clerk.shared
    @State private var pendingShareSlug: String?

    init() {
        // Configure RevenueCat at app launch
        Purchases.logLevel = .debug

        #if DEBUG
        // Use test API key for StoreKit testing in simulator/debug builds
        Purchases.configure(withAPIKey: "test_KPzYsqSoDJNXtANifSJSBXjJwoA")
        #else
        // Use production API key for release builds
        Purchases.configure(withAPIKey: "appl_hRZHpYyZEwGkIoBpcPfJQCkTXdx")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(pendingShareSlug: $pendingShareSlug)
                .environmentObject(tripStore)
                .environment(\.clerk, clerk)
                .task {
                    #if DEBUG
                    // Use test publishable key for development
                    clerk.configure(publishableKey: "pk_test_bWFnaWNhbC1sYWJyYWRvci0xNy5jbGVyay5hY2NvdW50cy5kZXYk")
                    #else
                    // Use production publishable key for release builds
                    clerk.configure(publishableKey: "pk_live_Y2xlcmsucmV3aW5kZWQuYXBwJA")
                    #endif
                    try? await clerk.load()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Handle Universal Links: https://rewinded.app/trip/{slug}
        if url.host == "rewinded.app" || url.host == "www.rewinded.app" {
            let pathComponents = url.pathComponents
            if pathComponents.count >= 3 && pathComponents[1] == "trip" {
                let slug = pathComponents[2]
                pendingShareSlug = slug
            }
        }
    }
}
