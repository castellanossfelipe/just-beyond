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
