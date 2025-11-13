import SwiftUI
import Clerk

@main
struct TripBankApp: App {
    @StateObject private var tripStore = TripStore()
    @State private var clerk = Clerk.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(tripStore)
                .environment(\.clerk, clerk)
                .task {
                    clerk.configure(publishableKey: "pk_test_bWFnaWNhbC1sYWJyYWRvci0xNy5jbGVyay5hY2NvdW50cy5kZXYk")
                    try? await clerk.load()
                }
        }
    }
}
