import SwiftUI
import RevenueCat

struct SubscriptionView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPackage: Package?
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Current Plan
                    currentPlanSection

                    // Storage Usage
                    if let usage = subscriptionManager.storageUsage {
                        StorageUsageView(usage: usage, showUpgradeButton: false)
                            .padding(.horizontal)
                    }

                    // Upgrade Options (only show for free users)
                    if subscriptionManager.currentTier == .free {
                        upgradeSection
                    }

                    // Features comparison
                    featuresSection

                    // Restore purchases
                    restoreButton

                    // Terms
                    termsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await subscriptionManager.fetchOfferings()
                await subscriptionManager.fetchStorageUsage()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(subscriptionManager.errorMessage ?? "Something went wrong")
            }
            .onChange(of: subscriptionManager.errorMessage) { _, newValue in
                if newValue != nil {
                    showingError = true
                }
            }
            .overlay {
                if subscriptionManager.isLoading {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 50))
                .foregroundStyle(.yellow)
                .padding()
                .background(
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                )

            Text("Rewinded Pro")
                .font(.title)
                .fontWeight(.bold)

            Text("Get more storage for all your travel memories")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }

    // MARK: - Current Plan

    private var currentPlanSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Current Plan")
                    .font(.headline)
                Spacer()
                Text(subscriptionManager.currentTier.displayName)
                    .font(.headline)
                    .foregroundStyle(subscriptionManager.currentTier == .pro ? .blue : .secondary)
            }

            if subscriptionManager.currentTier == .pro,
               let expiresAt = subscriptionManager.customerInfo?.entitlements["pro"]?.expirationDate {
                HStack {
                    Text("Renews")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(expiresAt, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Upgrade Options

    private var upgradeSection: some View {
        VStack(spacing: 16) {
            Text("Choose a Plan")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let offerings = subscriptionManager.offerings,
               let current = offerings.current {

                ForEach(current.availablePackages, id: \.identifier) { package in
                    PackageOptionView(
                        package: package,
                        isSelected: selectedPackage?.identifier == package.identifier,
                        onSelect: {
                            selectedPackage = package
                        }
                    )
                }

                // Purchase button
                if let selected = selectedPackage {
                    Button {
                        Task {
                            let success = await subscriptionManager.purchase(selected)
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        Text("Subscribe Now")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
            } else {
                // Loading state
                ProgressView()
                    .padding()
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 16) {
            Text("What's Included")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                FeatureRow(
                    icon: "externaldrive.fill",
                    title: "10 GB Storage",
                    description: "20x more storage for photos and videos",
                    isPro: true
                )

                FeatureRow(
                    icon: "arrow.up.circle.fill",
                    title: "Priority Support",
                    description: "Get help faster when you need it",
                    isPro: true
                )

                FeatureRow(
                    icon: "heart.fill",
                    title: "Support Development",
                    description: "Help us build more features",
                    isPro: true
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button {
            Task {
                _ = await subscriptionManager.restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.subheadline)
                .foregroundStyle(.blue)
        }
        .padding()
    }

    // MARK: - Terms

    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Service", destination: URL(string: "https://rewinded.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://rewinded.app/privacy")!)
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                Text("Processing...")
                    .foregroundStyle(.white)
                    .font(.headline)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

// MARK: - Package Option View

struct PackageOptionView: View {
    let package: Package
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(packageTitle)
                            .font(.headline)

                        if isBestValue {
                            Text("Best Value")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    Text(packageDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.headline)

                    if let period = periodText {
                        Text(period)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var packageTitle: String {
        switch package.packageType {
        case .monthly:
            return "Monthly"
        case .annual:
            return "Yearly"
        default:
            return package.storeProduct.localizedTitle
        }
    }

    private var packageDescription: String {
        switch package.packageType {
        case .monthly:
            return "Billed monthly"
        case .annual:
            return "Save 44% compared to monthly"
        default:
            return package.storeProduct.localizedDescription
        }
    }

    private var periodText: String? {
        switch package.packageType {
        case .monthly:
            return "/month"
        case .annual:
            return "/year"
        default:
            return nil
        }
    }

    private var isBestValue: Bool {
        package.packageType == .annual
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let isPro: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isPro ? .blue : .gray)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

#Preview {
    SubscriptionView()
}
