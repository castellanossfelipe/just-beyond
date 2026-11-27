import Testing
import JBGeo

private let view = OrthographicProjection(centre: LatLon(latDeg: 0, lonDeg: 0))

/// A line along the equator through the given longitudes.
private func equator(_ lonsDeg: Double...) -> [Vector3] {
    lonsDeg.map { LatLon(latDeg: 0, lonDeg: $0).unitVector }
}

private func radius(_ p: ProjectedPoint) -> Double {
    (p.x * p.x + p.y * p.y).squareRoot()
}

@Test func fullyVisibleLineIsOnePiece() {
    let line = equator(-40, 0, 40)
    #expect(view.visiblePieces(of: line) == [line.map { view.project($0) }])
}
