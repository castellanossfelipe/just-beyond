import Foundation
import Testing
import JBGeo

/// An iPhone 13 in portrait.
private let viewport = GlobeViewport(width: 390, height: 844, globeRadius: 187)

/// Touch updates at 60 a second, the camera turning steadily until it is at `end` on the lift.
private func samples(endingAt end: LatLon = LatLon(latDeg: 0, lonDeg: 0),
                     latDegPerSecond: Double = 0, lonDegPerSecond: Double,
                     updates: Int = 6) -> [CameraSample] {
    (0...updates).map { update in
        let before = Double(updates - update) / 60
        let lon = end.lonDeg - lonDegPerSecond * before
        return CameraSample(timeSeconds: 100 - before,
                            centre: LatLon(latDeg: end.latDeg - latDegPerSecond * before,
                                           lonDeg: remainder(lon, 360)))
    }
}

@Test func coastStartsFromHowTheGlobeWasMoving() throws {
    // Three times as fast until 100 ms before the lift: only the last 80 ms or so count.
    let turning = samples(latDegPerSecond: 20, lonDegPerSecond: 100)
    let first = turning[0]
    let earlier = (1...6).reversed().map { update in
        let before = Double(update) / 60
        return CameraSample(timeSeconds: first.timeSeconds - before,
                            centre: LatLon(latDeg: first.centre.latDeg - 60 * before,
                                           lonDeg: first.centre.lonDeg - 300 * before))
    }
    let coast = try #require(GlobeCoast(samples: earlier + turning, zoom: 1, viewport: viewport))
    #expect(abs(coast.latDegPerSecond - 20) < 1e-9)
    #expect(abs(coast.lonDegPerSecond - 100) < 1e-9)
}
