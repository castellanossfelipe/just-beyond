import Foundation
import Testing
import JBGeo

private let newYork = LatLon(latDeg: 40.71, lonDeg: -74.01)

/// The angle between two points on the unit sphere, in radians.
private func angle(_ a: Vector3, _ b: Vector3) -> Double {
    let x = a.y * b.z - a.z * b.y
    let y = a.z * b.x - a.x * b.z
    let z = a.x * b.y - a.y * b.x
    return atan2((x * x + y * y + z * z).squareRoot(), a.x * b.x + a.y * b.y + a.z * b.z)
}

@Test(arguments: [100.0, 2_500, 12_000])
func everyRingPointIsTheSameAngleFromCentre(radiusKm: Double) {
    let ring = RangeRing.points(around: newYork, radiusKm: radiusKm)
    #expect(!ring.isEmpty)
    for point in ring {
        #expect(abs(angle(newYork.unitVector, point) - radiusKm / 6_371) < 1e-9)
    }
}

@Test func ringSamplesEveryTwoDegreesOfBearing() throws {
    // From 0°N 0°E, the bearing of a point is the angle from the z axis towards the y axis.
    let ring = RangeRing.points(around: LatLon(latDeg: 0, lonDeg: 0), radiusKm: 2_500)
    try #require(ring.count == 181)
    for (i, point) in ring.dropLast().enumerated() {
        let bearingDeg = (atan2(point.y, point.z) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        #expect(abs(bearingDeg - Double(i) * 2) < 1e-9)
    }
}
