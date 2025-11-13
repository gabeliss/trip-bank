import SwiftUI

// Layout engine that positions moments in a Pinterest-style masonry arrangement
struct SpatialCanvasLayout {

    // Calculate positions using true masonry/waterfall algorithm
    static func calculateLayout(for moments: [Moment], canvasWidth: CGFloat) -> [UUID: MomentLayout] {
        var layouts: [UUID: MomentLayout] = [:]

        // Guard against invalid canvas width
        guard canvasWidth > 0 && canvasWidth.isFinite else {
            return layouts
        }

        let padding: CGFloat = 10 // Tight spacing for dense, cohesive layout
        let sideMargin: CGFloat = 16
        let maxWidth = canvasWidth - (sideMargin * 2)

        // Sort moments chronologically
        let sortedMoments = moments.sorted { ($0.date ?? $0.timestamp) < ($1.date ?? $1.timestamp) }

        // Masonry algorithm: track column heights
        let numberOfColumns = 2 // 2 columns for efficient packing
        var columnHeights = Array(repeating: CGFloat(30), count: numberOfColumns)
        let columnWidth = (maxWidth - padding * CGFloat(numberOfColumns - 1)) / CGFloat(numberOfColumns)

        for (index, moment) in sortedMoments.enumerated() {
            // Determine column span based on importance
            let columnSpan: Int
            let width: CGFloat

            switch moment.importance {
            case .hero:
                // Hero moments span both columns (but only first one)
                if index == 0 {
                    columnSpan = 2
                    width = maxWidth
                } else {
                    // Subsequent hero moments still large but single column
                    columnSpan = 1
                    width = columnWidth
                }
            case .large:
                // Large moments: mostly single column to reduce whitespace
                if index == 0 {
                    columnSpan = 2
                    width = maxWidth
                } else {
                    columnSpan = 1
                    width = columnWidth
                }
            case .medium:
                // Medium always single column for better packing
                columnSpan = 1
                width = columnWidth
            case .small:
                // Small always single column
                columnSpan = 1
                width = columnWidth
            }

            // Find the best column(s) to place this moment
            let (column, yPosition) = findBestColumn(
                columnHeights: columnHeights,
                columnSpan: columnSpan
            )

            // Calculate size based on importance and width
            let size = calculateSize(
                for: moment,
                targetWidth: width,
                index: index
            )

            // Calculate X position (no random offset to prevent overlap)
            let xPosition = sideMargin + (CGFloat(column) * (columnWidth + padding))

            let position = CGPoint(
                x: xPosition,
                y: yPosition
            )

            layouts[moment.id] = MomentLayout(
                position: position,
                size: size,
                zIndex: index
            )

            // Update ALL affected column heights to prevent overlap
            if columnSpan == 2 {
                // For full-width moments, update both columns
                for i in 0..<numberOfColumns {
                    columnHeights[i] = yPosition + size.height + padding
                }
            } else {
                // For single column moments, only update that column
                columnHeights[column] = yPosition + size.height + padding
            }
        }

        return layouts
    }

    // Find the best column(s) to place a moment
    private static func findBestColumn(
        columnHeights: [CGFloat],
        columnSpan: Int
    ) -> (column: Int, yPosition: CGFloat) {
        if columnSpan == 1 {
            // Find shortest column for single column moments
            if let shortestIndex = columnHeights.indices.min(by: { columnHeights[$0] < columnHeights[$1] }) {
                return (shortestIndex, columnHeights[shortestIndex])
            }
        } else {
            // For multi-column spans, MUST start after ALL columns are clear
            // This prevents overlap and excessive whitespace
            let maxHeight = columnHeights.max() ?? 0
            return (0, maxHeight)
        }

        return (0, columnHeights[0])
    }

    // Calculate size based on target width (from column layout)
    static func calculateSize(for moment: Moment, targetWidth: CGFloat, index: Int) -> CGSize {
        // Use explicit size if set
        if let explicitSize = moment.layoutSize {
            return sizeForCategory(explicitSize, availableWidth: targetWidth)
        }

        // Calculate height based on importance - NO RANDOMNESS for perfect layout
        let height: CGFloat
        let width = targetWidth

        switch moment.importance {
        case .small:
            // Small moments - compact and consistent
            height = 180

        case .medium:
            // Medium moments - balanced rectangles
            height = 220

        case .large:
            // Large moments - taller, more commanding
            height = 280

        case .hero:
            // Hero moments - very tall and prominent
            height = index == 0 ? 340 : 300
        }

        // Ensure minimum valid dimensions
        return CGSize(
            width: max(120, width),
            height: max(140, height)
        )
    }

    static func sizeForCategory(_ category: MomentSize, availableWidth: CGFloat) -> CGSize {
        let validWidth = max(100, availableWidth)

        let size: CGSize
        switch category {
        case .compact:
            size = CGSize(width: 150, height: 150)
        case .regular:
            size = CGSize(width: 200, height: 200)
        case .large:
            size = CGSize(width: min(300, validWidth * 0.7), height: 200)
        case .hero:
            size = CGSize(width: min(350, validWidth), height: 300)
        case .wide:
            size = CGSize(width: min(350, validWidth), height: 180)
        case .tall:
            size = CGSize(width: 180, height: 300)
        }

        // Ensure minimum valid dimensions
        return CGSize(
            width: max(100, size.width),
            height: max(100, size.height)
        )
    }
}

// Layout information for a single moment
struct MomentLayout {
    let position: CGPoint
    let size: CGSize
    let zIndex: Int
}
