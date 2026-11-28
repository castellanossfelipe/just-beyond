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

@Test func restingBeforeLiftDoesNotCoast() {
    let flung = samples(lonDegPerSecond: degPerSecond(pointsPerSecond: 1_000))
    // A still finger sends no updates; the next sample is the lift, 100 ms after the last move.
    let lift = CameraSample(timeSeconds: 100.1, centre: flung[flung.count - 1].centre)
    #expect(GlobeCoast(samples: flung + [lift], zoom: 1, viewport: viewport) == nil)
}

@Test func coastStopsBelowMinimumSpeed() throws {
    var view = GlobeCamera(centre: LatLon(latDeg: 0, lonDeg: 0))
    var coast = try #require(GlobeCoast(samples: samples(lonDegPerSecond: degPerSecond(pointsPerSecond: 1_000)),
                                        zoom: 1, viewport: viewport))
    // From 1,000 pt/s, 0.998 a millisecond reaches 10 pt/s after 2.300 s.
    coast.advance(&view, by: 2.29)
    #expect(!coast.isFinished)
    coast.advance(&view, by: 0.02)
    #expect(coast.isFinished)

    let stopped = view
    coast.advance(&view, by: 1)
    #expect(view == stopped)
}

@Test func fastFlingIsCapped() throws {
    func fling(pointsPerSecond speed: Double) throws -> (start: Double, turned: Double) {
        let rate = degPerSecond(pointsPerSecond: speed, zoom: 4)
        var view = GlobeCamera(centre: LatLon(latDeg: 0, lonDeg: 0), zoom: 4)
        var coast = try #require(GlobeCoast(samples: samples(lonDegPerSecond: rate), zoom: 4, viewport: viewport))
        let start = coast.lonDegPerSecond
        // Short enough not to go all the way round.
        coast.advance(&view, by: 0.2)
        return (start, view.centre.lonDeg)
    }
    let fast = try fling(pointsPerSecond: 10_000)
    let cap = try fling(pointsPerSecond: 4_000)
    #expect(abs(fast.start - cap.start) < 1e-9)
    #expect(abs(fast.turned - cap.turned) < 1e-9)
    #expect(abs(cap.start - degPerSecond(pointsPerSecond: 4_000, zoom: 4)) < 1e-9)
}

/// North and south.
@Test(arguments: [1.0, -1])
func coastStopsTiltingAtThePole(pole: Double) throws {
    var view = GlobeCamera(centre: LatLon(latDeg: 85 * pole, lonDeg: 0))
    var coast = try #require(GlobeCoast(
        samples: samples(endingAt: view.centre, latDegPerSecond: 60 * pole, lonDegPerSecond: 200),
        zoom: 1, viewport: viewport))
    let speed = viewport.globeRadius * hypot(60, 200 * cos(85 * .pi / 180)) * .pi / 180

    coast.advance(&view, by: 10)

    #expect(view.centre.latDeg == 90 * pole)
    // The longitude part carries on to the coast's own end.
    let total = 200 * 0.4995 * (1 - 10 / speed)
    #expect(abs(view.centre.lonDeg - total) < total * 0.001)
}

/// Longitudes of successive samples, their spacing, and the turning they show. The second turns
/// more than half way round inside the window, as a sideways drag near a pole can.
private let wrappingTurns: [(lat: Double, zoom: Double, lons: [Double], spacing: Double, degPerSecond: Double)] = [
    (0, 4, [179, -179], 0.1, 20),
    (85, 1, [0, 40, 80, 120, 160, -160, -120], 1.0 / 60, 2_400),
]

@Test(arguments: wrappingTurns)
func coastTakesTheShortWayAcrossTheAntimeridian(lat: Double, zoom: Double, lons: [Double], spacing: Double,
                                                degPerSecond: Double) throws {
    let turning = lons.enumerated().map { index, lon in
        CameraSample(timeSeconds: 100 + Double(index) * spacing, centre: LatLon(latDeg: lat, lonDeg: lon))
    }
    let coast = try #require(GlobeCoast(samples: turning, zoom: zoom, viewport: viewport))
    #expect(abs(coast.lonDegPerSecond - degPerSecond) < 1e-6)
}

@Test func shortFlickCoastsFromItsWholeLength() throws {
    // Three updates: 50 ms from touch to lift.
    let flick = samples(lonDegPerSecond: 100, updates: 3)
    let coast = try #require(GlobeCoast(samples: flick, zoom: 1, viewport: viewport))
    #expect(abs(coast.lonDegPerSecond - 100) < 1e-9)
    // One sample shows no turning.
    #expect(GlobeCoast(samples: [flick[0]], zoom: 1, viewport: viewport) == nil)
}
