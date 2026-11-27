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

@Test func lineOnTheFarSideDrawsNothing() {
    #expect(view.visiblePieces(of: equator(150, 180, -150)).isEmpty)
}

@Test func lineCrossingTheHorizonEndsOnTheLimb() throws {
    let pieces = view.visiblePieces(of: equator(60, 80, 110, 130))
    try #require(pieces.count == 1)
    #expect(pieces[0].count == 3)
    let end = try #require(pieces[0].last)
    #expect(abs(radius(end) - 1) < 1e-9)
    #expect(abs(end.depth) < 1e-9)
}

@Test func lineLeavingAndReturningMakesTwoPieces() {
    let pieces = view.visiblePieces(of: equator(60, 80, 120, 180, -120, -80, -60))
    #expect(pieces.count == 2)
}
