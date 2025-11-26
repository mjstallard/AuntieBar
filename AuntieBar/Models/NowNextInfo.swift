import Foundation

/// Represents a programme with its start and end times
struct ProgrammeSlot: Equatable, Sendable {
    let title: String
    let startTime: Date
    let endTime: Date
}

/// Bundles the current and next programmes for a station
struct NowNextInfo: Equatable, Sendable {
    let current: ProgrammeSlot
    let next: ProgrammeSlot?
}
