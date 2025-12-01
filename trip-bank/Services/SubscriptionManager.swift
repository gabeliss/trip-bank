import Foundation
import RevenueCat
import Clerk

// Storage limits in bytes (must match Convex storage.ts)
enum StorageTier: String, Codable {
    case free = "free"
    case pro = "pro"

    var limitBytes: Int64 {
        switch self {
        case .free: return 500 * 1024 * 1024 // 500 MB
        case .pro: return 10 * 1024 * 1024 * 1024 // 10 GB
        }
    }

    var limitFormatted: String {
        switch self {
        case .free: return "500 MB"
        case .pro: return "10 GB"
        }
    }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }
}

struct StorageUsage {
    let usedBytes: Int64
    let limitBytes: Int64
    let tier: StorageTier

    var percentUsed: Double {
        guard limitBytes > 0 else { return 0 }
        return min(100, Double(usedBytes) / Double(limitBytes) * 100)
    }

    var remainingBytes: Int64 {
        max(0, limitBytes - usedBytes)
    }

    var isAtLimit: Bool {
        usedBytes >= limitBytes
    }

    var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file)
    }

    var limitFormatted: String {
        tier.limitFormatted
    }

    var remainingFormatted: String {
        ByteCountFormatter.string(fromByteCount: remainingBytes, countStyle: .file)
    }
}

@MainActor
class SubscriptionManager: NSObject, ObservableObject {
    static let shared = SubscriptionManager()

    // Product identifiers (must match RevenueCat dashboard and StoreKit config)
    static let proMonthlyProductId = "com.rewinded.pro.monthly"
    static let proYearlyProductId = "com.rewinded.pro.yearly"

    @Published var currentTier: StorageTier = .free
    @Published var storageUsage: StorageUsage?
    @Published var isLoading = false
    @Published var offerings: Offerings?
    @Published var customerInfo: CustomerInfo?
    @Published var errorMessage: String?

    private override init() {
        super.init()
        // Set up delegate for real-time updates
        // Note: RevenueCat is configured in TripBankApp.init()
        Purchases.shared.delegate = self
    }

    // MARK: - User Identification

    /// Call this after user logs in with Clerk
    func identifyUser() async {
        guard let userId = await Clerk.shared.user?.id else {
            print("❌ [SubscriptionManager] No Clerk user to identify")
            return
        }

        do {
            let (customerInfo, _) = try await Purchases.shared.logIn(userId)
            self.customerInfo = customerInfo
            updateTierFromCustomerInfo(customerInfo)
            print("✅ [SubscriptionManager] User identified: \(userId)")
        } catch {
            print("❌ [SubscriptionManager] Failed to identify user: \(error)")
        }
    }

    /// Call this when user logs out
    func logoutUser() async {
        do {
            let customerInfo = try await Purchases.shared.logOut()
            self.customerInfo = customerInfo
            currentTier = .free
            print("✅ [SubscriptionManager] User logged out from RevenueCat")
        } catch {
            print("❌ [SubscriptionManager] Failed to logout: \(error)")
        }
    }

    // MARK: - Fetch Data

    /// Fetch available subscription offerings
    func fetchOfferings() async {
        isLoading = true
        errorMessage = nil

        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            print("✅ [SubscriptionManager] Fetched offerings: \(offerings.all.keys)")
        } catch {
            errorMessage = "Failed to load subscription options"
            print("❌ [SubscriptionManager] Failed to fetch offerings: \(error)")
        }

        isLoading = false
    }

    /// Fetch current customer info (subscription status)
    func fetchCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.customerInfo = customerInfo
            updateTierFromCustomerInfo(customerInfo)
        } catch {
            print("❌ [SubscriptionManager] Failed to fetch customer info: \(error)")
        }
    }

    /// Fetch storage usage from Convex
    func fetchStorageUsage() async {
        do {
            let usage = try await ConvexClient.shared.getStorageUsage()
            if let usage = usage {
                storageUsage = StorageUsage(
                    usedBytes: Int64(usage.usedBytes),
                    limitBytes: Int64(usage.limitBytes),
                    tier: StorageTier(rawValue: usage.tier) ?? .free
                )
                currentTier = StorageTier(rawValue: usage.tier) ?? .free
            }
        } catch {
            print("❌ [SubscriptionManager] Failed to fetch storage usage: \(error)")
        }
    }

    // MARK: - Purchases

    /// Purchase a subscription package
    func purchase(_ package: Package) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await Purchases.shared.purchase(package: package)

            if !result.userCancelled {
                self.customerInfo = result.customerInfo
                updateTierFromCustomerInfo(result.customerInfo)

                // Sync with Convex backend
                await syncSubscriptionToConvex()

                print("✅ [SubscriptionManager] Purchase successful!")
                isLoading = false
                return true
            } else {
                print("ℹ️ [SubscriptionManager] Purchase cancelled by user")
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            print("❌ [SubscriptionManager] Purchase failed: \(error)")
        }

        isLoading = false
        return false
    }

    /// Restore previous purchases
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            updateTierFromCustomerInfo(customerInfo)

            // Sync with Convex backend
            await syncSubscriptionToConvex()

            print("✅ [SubscriptionManager] Purchases restored")
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to restore purchases"
            print("❌ [SubscriptionManager] Failed to restore: \(error)")
        }

        isLoading = false
        return false
    }

    // MARK: - Helpers

    private func updateTierFromCustomerInfo(_ customerInfo: CustomerInfo) {
        // Check if user has active "pro" entitlement
        if customerInfo.entitlements["pro"]?.isActive == true {
            currentTier = .pro
        } else {
            currentTier = .free
        }
    }

    /// Sync subscription status to Convex backend
    private func syncSubscriptionToConvex() async {
        let expirationDate = customerInfo?.entitlements["pro"]?.expirationDate
        let expiresAt = expirationDate.map { Int($0.timeIntervalSince1970 * 1000) }

        do {
            try await ConvexClient.shared.updateSubscription(
                tier: currentTier.rawValue,
                expiresAt: expiresAt,
                revenueCatUserId: customerInfo?.originalAppUserId
            )
            print("✅ [SubscriptionManager] Synced subscription to Convex")
        } catch {
            print("❌ [SubscriptionManager] Failed to sync subscription: \(error)")
        }
    }

    // MARK: - Storage Check

    /// Check if user can upload a file of given size
    func canUpload(fileSize: Int64) -> (canUpload: Bool, message: String?) {
        guard let usage = storageUsage else {
            return (true, nil) // Allow if we haven't loaded usage yet
        }

        if usage.usedBytes + fileSize > usage.limitBytes {
            let remaining = ByteCountFormatter.string(fromByteCount: usage.remainingBytes, countStyle: .file)
            let fileFormatted = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)

            if currentTier == .free {
                return (false, "Not enough storage. You have \(remaining) remaining, but this file is \(fileFormatted). Upgrade to Pro for 10 GB of storage.")
            } else {
                return (false, "Not enough storage. You have \(remaining) remaining, but this file is \(fileFormatted).")
            }
        }

        return (true, nil)
    }
}

// MARK: - RevenueCat Delegate

extension SubscriptionManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.updateTierFromCustomerInfo(customerInfo)

            // Sync to Convex when subscription changes
            await self.syncSubscriptionToConvex()
        }
    }
}
