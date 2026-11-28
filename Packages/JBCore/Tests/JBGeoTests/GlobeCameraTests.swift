import Foundation
import Testing
import JBGeo

private func camera(lat: Double = 0, lon: Double = 0, zoom: Double = 1) -> GlobeCamera {
    GlobeCamera(centre: LatLon(latDeg: lat, lonDeg: lon), zoom: zoom)
}

private let radius = 200.0
private let oneRadianDeg = 180 / Double.pi

@Test func dragAtCentreTurnsOneRadianPerRadiusOfFingerTravel() {
    var across = camera()
    across.drag(dx: radius, dy: 0, globeRadius: radius)
    #expect(abs(abs(across.centre.lonDeg) - oneRadianDeg) < 1e-9)
    #expect(across.centre.latDeg == 0)

    var down = camera()
    down.drag(dx: 0, dy: radius, globeRadius: radius)
    #expect(abs(abs(down.centre.latDeg) - oneRadianDeg) < 1e-9)
    #expect(down.centre.lonDeg == 0)
}

@Test func dragRightBringsWestIntoView() {
    var view = camera(lat: 30, lon: -40)
    view.drag(dx: 50, dy: 0, globeRadius: radius)
    #expect(view.centre.lonDeg < -40)
    #expect(view.centre.latDeg == 30)
}

@Test func dragDownBringsNorthIntoView() {
    var view = camera(lat: 30, lon: -40)
    view.drag(dx: 0, dy: 50, globeRadius: radius)
    #expect(view.centre.latDeg > 30)
    #expect(view.centre.lonDeg == -40)
}

@Test func dragTurnsLessWhenZoomedIn() {
    var far = camera()
    var near = camera(zoom: 4)
    far.drag(dx: 40, dy: 40, globeRadius: radius)
    near.drag(dx: 40, dy: 40, globeRadius: radius)
    #expect(abs(near.centre.lonDeg - far.centre.lonDeg / 4) < 1e-9)
    #expect(abs(near.centre.latDeg - far.centre.latDeg / 4) < 1e-9)
}

@Test(arguments: [(45.0, 0.707_106_781_186_547_6), (60, 0.5), (-60, 0.5), (85, 0.2), (90, 0.2)])
func dragAtHighLatitudeStillFollowsTheFinger(lat: Double, widthOfParallel: Double) {
    var view = camera(lat: lat)
    view.drag(dx: 20, dy: 0, globeRadius: radius)
    // A narrower parallel needs more longitude for the same travel, down to a floor near the poles.
    #expect(abs(view.centre.lonDeg - -(0.1 * oneRadianDeg / widthOfParallel)) < 1e-9)
}

@Test(arguments: [(1.0, 90.0), (-1, -90)])
func latitudeStopsAtThePoles(direction: Double, pole: Double) {
    var view = camera(lat: 80 * direction)
    view.drag(dx: 0, dy: 1_000 * direction, globeRadius: radius)
    #expect(view.centre.latDeg == pole)
}

@Test(arguments: [(179.0, -1.0), (-179, 1), (0, 20)])
func longitudeWrapsAtTheAntimeridian(startLon: Double, turns: Double) {
    // Drag far enough to cross the antimeridian, or to go many times round.
    var view = camera(lon: startLon)
    let travel = turns == 20 ? turns * 2 * .pi * radius + 1 : turns * 10
    view.drag(dx: travel, dy: 0, globeRadius: radius)
    #expect(view.centre.lonDeg >= -180 && view.centre.lonDeg < 180)
    let expected = startLon - travel / radius * oneRadianDeg
    #expect(abs(remainder(view.centre.lonDeg - expected, 360)) < 1e-9)
}
