import SwiftUI

struct StorageUsageView: View {
    let usage: StorageUsage
    var showUpgradeButton: Bool = true
    var onUpgradeTap: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Storage", systemImage: "externaldrive.fill")
                    .font(.headline)

                Spacer()

                Text(usage.tier.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(usage.tier == .pro ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundStyle(usage.tier == .pro ? .white : .primary)
                    .clipShape(Capsule())
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    // Filled portion
                    RoundedRectangle(cornerRadius: 6)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(1.0, usage.percentUsed / 100), height: 12)
                }
            }
            .frame(height: 12)

            // Usage text
            HStack {
                Text("\(usage.usedFormatted) of \(usage.limitFormatted) used")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(usage.percentUsed))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(progressColor)
            }

            // Warning or upgrade prompt
            if usage.isAtLimit {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Storage full. Delete media or upgrade to continue.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            } else if usage.percentUsed >= 80 && usage.tier == .free {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.yellow)
                    Text("Running low on storage.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }

            // Upgrade button (only for free tier)
            if showUpgradeButton && usage.tier == .free {
                Button {
                    onUpgradeTap?()
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Upgrade to Pro")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var progressColor: Color {
        if usage.percentUsed >= 90 {
            return .red
        } else if usage.percentUsed >= 75 {
            return .orange
        } else {
            return .blue
        }
    }
}

// Compact version for inline display
struct StorageUsageCompactView: View {
    let usage: StorageUsage

    var body: some View {
        HStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: min(1.0, usage.percentUsed / 100))
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(usage.percentUsed))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(progressColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Storage")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(usage.usedFormatted) / \(usage.limitFormatted)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var progressColor: Color {
        if usage.percentUsed >= 90 {
            return .red
        } else if usage.percentUsed >= 75 {
            return .orange
        } else {
            return .blue
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StorageUsageView(
            usage: StorageUsage(
                usedBytes: 250 * 1024 * 1024,
                limitBytes: 500 * 1024 * 1024,
                tier: .free
            )
        )

        StorageUsageView(
            usage: StorageUsage(
                usedBytes: 450 * 1024 * 1024,
                limitBytes: 500 * 1024 * 1024,
                tier: .free
            )
        )

        StorageUsageView(
            usage: StorageUsage(
                usedBytes: 2 * 1024 * 1024 * 1024,
                limitBytes: 10 * 1024 * 1024 * 1024,
                tier: .pro
            ),
            showUpgradeButton: false
        )

        StorageUsageCompactView(
            usage: StorageUsage(
                usedBytes: 250 * 1024 * 1024,
                limitBytes: 500 * 1024 * 1024,
                tier: .free
            )
        )
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
}
