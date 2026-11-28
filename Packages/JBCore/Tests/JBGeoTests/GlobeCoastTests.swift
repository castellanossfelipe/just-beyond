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

/// Longitude turning that moves the screen middle at `speed` points a second.
private func degPerSecond(pointsPerSecond speed: Double, lat: Double = 0, zoom: Double = 1) -> Double {
    speed / (viewport.globeRadius * zoom * cos(lat * .pi / 180)) * 180 / .pi
}

@Test func coastSlowsLikeAScrollView() throws {
    let rate = degPerSecond(pointsPerSecond: 1_000)
    var view = GlobeCamera(centre: LatLon(latDeg: 0, lonDeg: 0))
    var coast = try #require(GlobeCoast(samples: samples(lonDegPerSecond: rate), zoom: 1, viewport: viewport))

    coast.advance(&view, by: 0.1)
    #expect(abs(coast.lonDegPerSecond - rate * pow(0.998, 100)) < 1e-9)

    // Long enough to be over. It stops at 10 of its 1,000 pt/s, so that share of the turn is not made.
    coast.advance(&view, by: 10)
    let total = rate * 0.4995 * (1 - 10.0 / 1_000)
    #expect(abs(view.centre.lonDeg - total) < total * 0.001)
    #expect(view.centre.latDeg == 0)
}

/// The second duration runs past the end of the coast.
@Test(arguments: [0.5, 5.0])
func coastIsTheSameInOneStepOrMany(seconds: Double) throws {
    var inOne = GlobeCamera(centre: LatLon(latDeg: 10, lonDeg: 0))
    var inTen = inOne
    var one = try #require(GlobeCoast(samples: samples(endingAt: inOne.centre, latDegPerSecond: 30, lonDegPerSecond: 200),
                                      zoom: 1, viewport: viewport))
    var ten = one

    one.advance(&inOne, by: seconds)
    for _ in 1...10 { ten.advance(&inTen, by: seconds / 10) }

    #expect(abs(inOne.centre.latDeg - inTen.centre.latDeg) < 1e-9)
    #expect(abs(inOne.centre.lonDeg - inTen.centre.lonDeg) < 1e-9)
    #expect(abs(one.lonDegPerSecond - ten.lonDegPerSecond) < 1e-9)
}

/// The speed is the screen middle's, so a parallel counts for less away from the equator, and
/// the same turn counts for more zoomed in.
@Test(arguments: [0.0, 60], [1.0, 4])
func slowReleaseDoesNotCoast(lat: Double, zoom: Double) {
    func coast(pointsPerSecond speed: Double) -> GlobeCoast? {
        let rate = degPerSecond(pointsPerSecond: speed, lat: lat, zoom: zoom)
        return GlobeCoast(samples: samples(endingAt: LatLon(latDeg: lat, lonDeg: 0), lonDegPerSecond: rate),
                          zoom: zoom, viewport: viewport)
    }
    #expect(coast(pointsPerSecond: 99) == nil)
    #expect(coast(pointsPerSecond: 101) != nil)
}
