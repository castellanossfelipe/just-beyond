import Testing
import JBGeo

private func expectVector(_ v: Vector3, _ x: Double, _ y: Double, _ z: Double,
                          sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(abs(v.x - x) < 1e-12, "x is \(v.x)", sourceLocation: sourceLocation)
    #expect(abs(v.y - y) < 1e-12, "y is \(v.y)", sourceLocation: sourceLocation)
    #expect(abs(v.z - z) < 1e-12, "z is \(v.z)", sourceLocation: sourceLocation)
}

@Test func latZeroLonZeroIsPlusX() {
    expectVector(LatLon(latDeg: 0, lonDeg: 0).unitVector, 1, 0, 0)
}
