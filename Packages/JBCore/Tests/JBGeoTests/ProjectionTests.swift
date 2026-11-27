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
