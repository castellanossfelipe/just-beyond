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
