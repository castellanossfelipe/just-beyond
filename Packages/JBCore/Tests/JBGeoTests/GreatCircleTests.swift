import Testing
import JBGeo

private let newYork = LatLon(latDeg: 40.71, lonDeg: -74.01)
private let london = LatLon(latDeg: 51.51, lonDeg: -0.13)

@Test func arcEndpointsAreExact() {
    let arc = GreatCircle.arc(from: newYork, to: london)
    #expect(arc.first == newYork.unitVector)
    #expect(arc.last == london.unitVector)
}

@Test func arcPointsAreUnitVectors() {
    for v in GreatCircle.arc(from: newYork, to: london) {
        #expect(abs(length(v) - 1) < 1e-12)
    }
}

private func length(_ v: Vector3) -> Double {
    (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot()
}
