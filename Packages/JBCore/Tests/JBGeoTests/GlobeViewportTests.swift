import Testing
import JBGeo

/// An iPhone 13 in portrait.
private let viewport = GlobeViewport(width: 390, height: 844, globeRadius: 187)

/// Camera centre, zoom, and a place that camera can see.
private let visiblePlaces: [(LatLon, Double, LatLon)] = [
    (LatLon(latDeg: 0, lonDeg: 0), 1, LatLon(latDeg: 0, lonDeg: 0)),
    (LatLon(latDeg: 0, lonDeg: 0), 1, LatLon(latDeg: 30, lonDeg: 40)),
    (LatLon(latDeg: 45, lonDeg: -40), 4, LatLon(latDeg: 51.5, lonDeg: -30)),
    (LatLon(latDeg: -45, lonDeg: 170), 8, LatLon(latDeg: -40, lonDeg: -175)),
    (LatLon(latDeg: 80, lonDeg: 10), 1, LatLon(latDeg: 70, lonDeg: -170)),
    (LatLon(latDeg: 0, lonDeg: 0), 1, LatLon(latDeg: 0, lonDeg: 85)),
]

@Test(arguments: visiblePlaces)
func screenPointRoundTrip(centre: LatLon, zoom: Double, place: LatLon) throws {
    let camera = GlobeCamera(centre: centre, zoom: zoom)
    let point = try #require(camera.screenPoint(of: place, in: viewport))
    let back = try #require(camera.place(at: point, in: viewport))
    #expect(angle(back.unitVector, place.unitVector) < 1e-9)
}
