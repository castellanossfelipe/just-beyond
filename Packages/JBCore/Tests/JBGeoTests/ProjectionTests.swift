import Testing
import JBGeo

private let atOrigin = OrthographicProjection(centre: LatLon(latDeg: 0, lonDeg: 0))

@Test func pointThirtyDegreesEastProjectsToHalfRadiusRight() {
    let p = atOrigin.project(LatLon(latDeg: 0, lonDeg: 30))
    #expect(abs(p.x - 0.5) < 1e-12)
    #expect(abs(p.y) < 1e-12)
}

@Test func pointThirtyDegreesNorthProjectsToHalfRadiusUp() {
    let p = atOrigin.project(LatLon(latDeg: 30, lonDeg: 0))
    #expect(abs(p.x) < 1e-12)
    #expect(abs(p.y - 0.5) < 1e-12)
}

@Test(arguments: [
    LatLon(latDeg: 0, lonDeg: 90), LatLon(latDeg: 0, lonDeg: -90),
    LatLon(latDeg: 90, lonDeg: 0), LatLon(latDeg: -90, lonDeg: 0),
])
func limbPointsLieOnTheUnitCircle(point: LatLon) {
    let p = atOrigin.project(point)
    #expect(abs((p.x * p.x + p.y * p.y).squareRoot() - 1) < 1e-12)
    #expect(abs(p.depth) < 1e-12)
}

@Test func antipodeIsHidden() {
    #expect(atOrigin.project(LatLon(latDeg: 0, lonDeg: 180)).depth < 0)
}

@Test(arguments: [
    LatLon(latDeg: 0, lonDeg: -30), LatLon(latDeg: -17, lonDeg: -30),
    LatLon(latDeg: 52, lonDeg: -64), LatLon(latDeg: 65, lonDeg: -10),
])
func centreProjectsToOrigin(centre: LatLon) {
    let p = OrthographicProjection(centre: centre).project(centre)
    #expect(abs(p.x) < 1e-12)
    #expect(abs(p.y) < 1e-12)
}

@Test(arguments: [
    LatLon(latDeg: 0, lonDeg: 89), LatLon(latDeg: -89, lonDeg: 0),
    LatLon(latDeg: 40, lonDeg: -60), LatLon(latDeg: -35, lonDeg: 50),
])
func nearsideDepthIsPositive(point: LatLon) {
    #expect(atOrigin.project(point).depth > 0)
}

@Test func northStaysUpWhenCentreMoves() {
    for lonDeg in [-135.0, 0, 70] {
        let view = OrthographicProjection(centre: LatLon(latDeg: 60, lonDeg: lonDeg))
        let pole = view.project(LatLon(latDeg: 90, lonDeg: 0))
        #expect(abs(pole.x) < 1e-12)
        #expect(pole.y > 0)
    }
}

@Test func antimeridianNeighboursProjectClose() {
    let view = OrthographicProjection(centre: LatLon(latDeg: 0, lonDeg: 180))
    let west = view.project(LatLon(latDeg: 0, lonDeg: 179.9))
    let east = view.project(LatLon(latDeg: 0, lonDeg: -179.9))
    #expect(abs(east.x - west.x) < 0.01)
    #expect(abs(east.y - west.y) < 0.01)
    #expect(west.depth > 0 && east.depth > 0)
}

@Test(arguments: [90.0, -90])
func centreOnAPoleStillProjectsToFiniteNumbers(latDeg: Double) {
    let view = OrthographicProjection(centre: LatLon(latDeg: latDeg, lonDeg: 37))
    for point in [LatLon(latDeg: 90, lonDeg: 0), LatLon(latDeg: 0, lonDeg: 120), LatLon(latDeg: -90, lonDeg: 0)] {
        let p = view.project(point)
        #expect(p.x.isFinite && p.y.isFinite && p.depth.isFinite)
    }
}
