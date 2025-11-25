import Foundation

/// Represents a BBC radio station with its metadata and streaming URL
struct RadioStation: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let streamURL: URL
    let category: RadioStationCategory
    let isUKOnly: Bool

    init(id: String? = nil, name: String, streamURL: URL, category: RadioStationCategory, isUKOnly: Bool = false) {
        self.id = id ?? UUID().uuidString
        self.name = name
        self.streamURL = streamURL
        self.category = category
        self.isUKOnly = isUKOnly
    }
}

/// Categories for organizing BBC radio stations
enum RadioStationCategory: String, Codable, CaseIterable {
    case national = "National"
    case regional = "Regional"
    case nations = "Nations & Regions"

    var sortOrder: Int {
        switch self {
        case .national: return 0
        case .nations: return 1
        case .regional: return 2
        }
    }
}
