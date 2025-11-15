import Foundation
import SwiftUI

struct Trip: Identifiable, Codable {
    let id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var coverImageName: String?
    var coverImageStorageId: String?
    var mediaItems: [MediaItem]
    var moments: [Moment]

    init(id: UUID = UUID(),
         title: String,
         startDate: Date = Date(),
         endDate: Date = Date(),
         coverImageName: String? = nil,
         coverImageStorageId: String? = nil,
         mediaItems: [MediaItem] = [],
         moments: [Moment] = []) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.coverImageName = coverImageName
        self.coverImageStorageId = coverImageStorageId
        self.mediaItems = mediaItems
        self.moments = moments
    }

    var dateRangeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return formatter.string(from: startDate)
        } else {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
    }
}
