import Foundation
@testable import AuntieBar

/// Mock now-playing service for testing
actor MockNowPlayingService: NowPlayingServiceProtocol {
    nonisolated(unsafe) var mockNowPlayingInfo: NowPlayingInfo?
    nonisolated(unsafe) var mockNowNextInfo: NowNextInfo?
    nonisolated(unsafe) var shouldReturnNil = false
    nonisolated(unsafe) var fetchCallCount = 0
    nonisolated(unsafe) var nowNextCallCount = 0
    nonisolated(unsafe) var lastServiceIdFetched: String?

    func fetchNowPlaying(for serviceId: String) async -> NowPlayingInfo? {
        fetchCallCount += 1
        lastServiceIdFetched = serviceId

        if shouldReturnNil {
            return nil
        }

        return mockNowPlayingInfo
    }

    func fetchNowNext(for serviceId: String) async -> NowNextInfo? {
        nowNextCallCount += 1
        lastServiceIdFetched = serviceId

        if shouldReturnNil {
            return nil
        }

        return mockNowNextInfo
    }

    func reset() {
        mockNowPlayingInfo = nil
        mockNowNextInfo = nil
        shouldReturnNil = false
        fetchCallCount = 0
        nowNextCallCount = 0
        lastServiceIdFetched = nil
    }
}
